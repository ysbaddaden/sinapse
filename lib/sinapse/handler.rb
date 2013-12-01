module Sinapse
  class Handler
    attr_accessor :socket, :channel_name

    def initialize(socket, channel_name)
      self.socket = socket
      self.channel_name = channel_name

      socket.retry Config.retry

      # TODO: actual authentication of user
      write_sse('ok', 'authentication', 0)

      subscribe
    end

    def subscribe
      # NOTE: redis.subscribe is blocking IO
      redis.subscribe(channel_name) do |on|
        on.message { |channel, payload| write_sse(payload, channel, 0) }
      end
    rescue IOError
    ensure
      redis.quit if redis.connected?
    end

    def write_sse(data, event = nil, id = nil)
      socket.id(id) if id
      socket.event(event) if event
      socket.data(data)
      #socket.write "data: %s\n" % data.gsub(/\n/, "\ndata: ") + "\n"
    rescue Reel::SocketError
      close
    rescue
      close
      raise
    end

    def close
      # NOTE: Redis#subscribe replaces the celluloid client by some blocking IO,
      #   we thus need to unsubscribe first, which will unlock #subscribe (which
      #   will ensure that we disconnect the connection to redis).
      if redis.subscribed?
        redis.unsubscribe
      else
        redis.quit
      end

      socket.close unless socket.closed?
    end

    def redis
      @redis ||= Redis.new(driver: 'celluloid')
    end
  end
end
