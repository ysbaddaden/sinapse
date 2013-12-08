module Sinapse
  class Server < Goliath::API
    use Goliath::Rack::Params
    use Goliath::Rack::Heartbeat  # respond to /status with 200, OK (monitoring, etc)
    use Goliath::Rack::Validation::RequestMethod, %w(GET POST)
    use Goliath::Rack::Validation::RequiredParam, { key: 'access_token' }

    def keep_alive
      @keep_alive ||= KeepAlive.new
    end

    def on_close(env)
      close_redis(env['redis']) if env['redis']
      keep_alive.delete(env)
    end

    def response(env)
      env['redis'] = Redis.new(:driver => :synchrony)

      channels = authenticate(env)
      return [401, {}, []] if channels.nil? || channels.empty?

      EM.next_tick do
        sse(env, :ok, :authentication, retry: Config.retry)
        subscribe(env, channels)
        keep_alive << env
      end

      chunked_streaming_response(200,
        'Access-Control-Allow-Origin' => Config.cors_origin,
        'Connection' => 'close',
        'Content-Type' => 'text/event-stream'
      )
    end

    private

      def authenticate(env)
        user = env['redis'].get("sinapse:token:#{params['access_token']}")
        env['redis'].smembers("sinapse:channels:#{user}") if user
      end

      # TODO: (un)subscribe to channels when a user gains/loses permissions on a channel
      def subscribe(env, channels)
        EM.synchrony do
          env['redis'].subscribe(*channels) do |on|
            on.message { |channel, message| sse(env, message, channel) }
          end
          env['redis'].quit
        end
      end

      def sse(env, data, event = nil, options = {})
        message = []
        message << "retry: %d" % options[:retry] if options[:retry]
        message << "id: %d" % options[:id] if options[:id]
        message << "event: %s" % event if event
        message << "data: %s" % data.to_s.gsub(/\n/, "\ndata: ")
        env.chunked_stream_send message.join("\n") + "\n\n"
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
