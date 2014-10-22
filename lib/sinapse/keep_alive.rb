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
        EM.add_periodic_timer(Sinapse.config.keep_alive) do
          @queue.each { |env| env.chunked_stream_send ":\n" }
        end
      end
  end
end
