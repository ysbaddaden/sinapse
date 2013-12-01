require 'bundler/setup'
require 'redis'
require 'celluloid/io'

module Sinapse
  class Server
    include Celluloid::IO

    finalizer :finalize

    def initialize(server_definition)
      @sockets = []

      @server = if server_definition.start_with?('/')
                  UNIXServer.new(server_definition)
                else
                  hostname, port = server_definition.split(':')
                  TCPServer.new(hostname, port.to_i)
                end
      async.run
    end

    def finalize
      @server.close if @server && !@server.closed?
      @sockets.pop { |socket| socket.close unless socket.closed? }
    end

    def run
      loop do
        @sockets.push(socket = @server.accept)
        async.handle_connection(socket)
      end
    end

    def handle_connection(socket)
      # TODO: parse the HTTP request (to get the user + token parameters)
      # TODO: authenticate the user (to access the list of channels to listen to)
      # TODO: (un)listen for the channels when the list is modified
      # TODO: check for missed events and write them back

      socket.write "HTTP/1.1 200 Ok\r\n" <<
                   "Connection: close\r\n" <<
                   "Content-Type: text/event-stream\r\n" <<
                   "\r\n"

      socket.write "id: 0\n" <<
                   "event: authentication\n" <<
                   "data: ok\n" <<
                   "\n"
      socket.flush

      conn = connect

      conn.subscribe 'sinapse' do |on|
        on.message do |channel, payload|
          socket.write "id: 0\nevent: #{channel}\ndata: #{payload.strip}\n\n"
          socket.flush
        end
      end

      sleep

    rescue EOFError, IOError, Errno::EPIPE, Errno::ECONNRESET
    ensure
      conn.close if conn rescue nil
      socket.close if socket rescue nil
      @sockets.delete(socket)
    end

    def connect
      Redis.new(:driver => 'celluloid')
    end
  end
end
