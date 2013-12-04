require 'bundler/setup'
require 'eventmachine'
require 'redis'

module Sinapse
  class DeferrableBody
    include EventMachine::Deferrable

    def each(&block)
      @callback = block
    end

    def append(data)
      data.each { |chunk| @callback.call(chunk) } if @callback
    end

    def sse(data, event)
      append [
        "event: %s\n" % event.to_s,
        "data: %s\n\n" % data.to_s.gsub(/\n/, "\ndata: ")
      ]
    end
  end

  class Server
    def call(env)
      body = DeferrableBody.new
      redis = Redis.new(:driver => :synchrony)

      headers = {
        'Access-Control-Allow-Origin' => '*',
        'Connection' => 'close',
        'Content-Type' => 'text/event-stream',
        'X-Accel-Buffering' => 'no',
      }

      EM.synchrony do
        redis.subscribe('sinapse') do |on|
          on.message { |channel, message| body.sse(message, channel) }
        end

        redis.quit
        body.succeed
      end

      EM.add_periodic_timer(5) do
        body.append [":\n"]
      end

      EM.next_tick do
        env['async.callback'].call [200, headers, body]

        body.append ["retry: 5000\n"]
        body.sse(:ok, :authentication)
      end

      env['async.close'].callback { redis.unsubscribe }
      env['async.close'].errback  { redis.unsubscribe }

      throw :async
    end
  end
end

run Sinapse::Server.new

