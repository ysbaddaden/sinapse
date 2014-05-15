require 'goliath'
require 'goliath/websocket'
require 'sinapse/config'
require 'sinapse/keep_alive'
require 'sinapse/cross_origin_resource_sharing'
require 'msgpack'
require 'json'

module Sinapse
  class Server < Goliath::WebSocket
    use Sinapse::Rack::CrossOriginResourceSharing, origin: Sinapse.config.cors_origin
    use Goliath::Rack::Params
    use Goliath::Rack::Heartbeat  # respond to /status with 200, OK (monitoring, etc)
    use Goliath::Rack::Validation::RequestMethod, %w(GET POST)
    use Goliath::Rack::Validation::RequiredParam, { key: 'access_token' }

    def keep_alive
      @keep_alive ||= KeepAlive.new
    end

    def response(env)
      env['redis'] = Redis.new(:driver => :synchrony, :url => Sinapse.config.redis_url)

      authenticate(env)
      return [401, {}, []] if env["sinapse.user"].nil? || env["sinapse.channels"].empty?

      if env["HTTP_UPGRADE"] == "websocket"
        super
      else
        EM.next_tick do
          sse(env, :ok, :authentication, retry: Sinapse.Config.retry)
          subscribe(env)
          keep_alive << env
        end

        chunked_streaming_response(200, response_headers(env))
      end
    end

    def on_open(env)
      EM.next_tick do
        subscribe(env)

        EM.next_tick do
          ws(env, "authentication: ok")
        end
      end
    end

    def on_close(env)
      close_redis(env['redis']) if env['redis']
      keep_alive.delete(env) unless env['handler']
    end

    def on_error(env, error)
      env.logger.debug "ERROR: #{error}"
    end

    private

      def authenticate(env)
        user = env['redis'].get("sinapse:tokens:#{params['access_token']}")
        if user
          env["sinapse.user"] = user
          env["sinapse.channels"] = env['redis'].smembers("sinapse:channels:#{user}")
        end
      end

      def subscribe(env)
        user, channels = env["sinapse.user"], env["sinapse.channels"]

        EM.synchrony do
          env['redis'].psubscribe("sinapse:channels:#{user}:*") do |on|
            on.psubscribe do
              env['redis'].subscribe(*channels)
            end

            on.pmessage do |_, channel, message|
              update_subscriptions(env, message, channel)
            end

            on.message do |channel, data|
              event, message = unpack(channel, data)
              push(env, message, event)
            end
          end
          env['redis'].quit
        end
      end

      def update_subscriptions(env, message, channel)
        return env['redis'].subscribe(message)   if channel.end_with?(':add')
        return env['redis'].unsubscribe(message) if channel.end_with?(':remove')
      end

      def unpack(channel, data)
        message = MessagePack.unpack(data)
        if message.is_a?(Array)
          message
        else
          event = Sinapse.config.channel_event ? channel : nil
          [event, message]
        end
      end

      def push(env, message, event = nil)
        if env['handler']
          ws(env, message, event)
        else
          sse(env, message, event)
        end
      end

      def ws(env, data, event = nil)
        if event
          env.handler.send_text_frame({ event: event, data: data }.to_json)
        else
          env.handler.send_text_frame(data)
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

      def response_headers(env)
        headers = {
          'Connection' => 'close',
          'Content-Type' => 'text/event-stream'
        }
        if env['cors.headers']
          headers.merge(env['cors.headers'])
        else
          headers
        end
      end
  end
end
