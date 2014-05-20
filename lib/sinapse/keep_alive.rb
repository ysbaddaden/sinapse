module Sinapse
  class KeepAlive
    def initialize
      @queue = []
    end

    def <<(env)
      @queue << env
      @timer = start if @queue.size == 1
    end

    def delete(env)
      @queue.delete(env)
      @timer.cancel if @timer && @queue.size == 0
    end

    protected

      def start
        EM.add_periodic_timer(Config.keep_alive) do
          @queue.each { |env| env.chunked_stream_send comment }
        end
      end

      # NOTE: libcurl requires a minimum of 1 byte for each elapsed second to
      #       keep the connection open. See CURLOPT_LOW_SPEED_LIMIT and
      #       CURLOPT_LOW_SPEED_TIME for more informations.
      #
      #       We are sending more bytes here to avoid issues with high
      #       latencies.
      def comment
        @comment ||= if Config.libcurl
                       ":\n" * Config.keep_alive
                     else
                       ":\n"
                     end
      end
  end
end
