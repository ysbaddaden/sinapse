module Sinapse
  class Server < Reel::Server
    include Celluloid::Logger

    def initialize(server, options = {})
      @handlers = []
      async.monitor

      super server, options, &method(:on_connection)
      info "Server ready on #{server.addr[2]}:#{server.addr[1]}"
    end

    def quit
      @handlers.pop.tap(&:close) until @handlers.empty?
    end

    def monitor
      every(Config.ping) { keep_connections_alive }
      every(1) { cleanup_dead_connections }
    end

    private

      def on_connection(connection)
        connection.each_request { |request| handle_request(request) }
      end

      def handle_request(request)
        params = parse_query_string(request)

        stream = Reel::EventStream.new do |socket|
          @handlers << Handler.new(socket, params['channel'])
        end

        headers = {
          'Access-Control-Allow-Origin' => Config.access_control_allow_origin,
          'Cache-Control' => 'no-cache',
          'Connection' => 'close',
          'Content-Type' => 'text/event-stream',
          'X-Accel-Buffering' => 'no', # skips nginx' buffer
        }
        request.respond Reel::StreamResponse.new(:ok, headers, stream)
      end

      def parse_query_string(request)
        Hash[*(request.query_string || '')
          .split(/&/)
          .map { |kv| kv.include?('=') ? kv.split(/=/) : [kv, ''] }
          .flatten
          .map { |s| CGI.unescape(s) }
        ]
      end

      def keep_connections_alive
        @handlers.each { |handler| send_ping(handler) }
      end

      def cleanup_dead_connections
        @handlers.each do |handler|
          next unless handler.socket.closed?
          handler.close
          @handlers.delete(handler)
        end
      end

      def send_ping(handler)
        handler.socket.write(":\n")
      rescue Reel::SocketError
        handler.close
        @handlers.delete(handler)
      end
  end
end
