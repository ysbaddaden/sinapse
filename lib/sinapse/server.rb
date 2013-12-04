module Sinapse
  class Server < Goliath::API
    use Goliath::Rack::Params
    use Goliath::Rack::Heartbeat  # respond to /status with 200, OK (monitoring, etc)

    use Goliath::Rack::Validation::RequestMethod, %w(GET POST)
    use Goliath::Rack::Validation::RequiredParam, { key: 'access_token' }

    def on_close(env)
      close_redis(env['redis']) if env['redis']
    end

    def response(env)
      headers = {
        'Access-Control-Allow-Origin' => Config.cors_origin,
        'Connection' => 'close',
        'Content-Type' => 'text/event-stream',
        'X-Accel-Buffering' => 'no',
        'X-Stream' => 'Goliath',
      }

      env['redis'] = Redis.new(:driver => :synchrony)

      # TODO: actually authentify the user
      EM.next_tick do
        sse(env, :ok, :authentication, retry: Config.retry)

        # TODO: subcribe to user's authorized channels
        # TODO: (un)subscribe to channels when a user gains/loses permissions on a channel
        EM.synchrony do
          env['redis'].subscribe('sinapse') do |on|
            on.message { |channel, message| sse(env, message, channel) }
          end

          env['redis'].quit
        end

        # FIXME: clear the periodic timer on connection close
        # OPTIMIZE: use a middleware for that (using a pool & a single periodic timer)
        EM.add_periodic_timer(Config.keep_alive) do
          puts "<== PERIODIC TIMER"
          env.stream_send ":\n"
        end
      end

      streaming_response(200, headers)
    end

    private

      def sse(env, data, event = nil, options = {})
        message = []
        message << "retry: %d" % options[:retry] if options[:retry]
        message << "id: %d" % options[:id] if options[:id]
        message << "event: %s" % event if event
        message << "data: %s" % data.to_s.gsub(/\n/, "\ndata: ")
        env.stream_send message.join("\n") + "\n\n"
      end

      def close_redis(redis)
        if redis.subscribed?
          redis.unsubscribe
        else
          redis.quit
        end
      end
  end
end
