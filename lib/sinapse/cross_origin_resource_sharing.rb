module Sinapse
  module Rack
    class CrossOriginResourceSharing
      include Goliath::Rack::AsyncMiddleware

      def initialize(app, options = {})
        super(app)

        @origin  = options[:origin] || '*'
        @methods = options[:methods] || %w(GET POST)
        @max_age = options[:max_age]
      end

      def call(env)
        env['HTTP_ORIGIN'] ||= env['HTTP_X_ORIGIN']
        env['cors.headers'] = nil

        if env['HTTP_ORIGIN']
          if env['REQUEST_METHOD'] == 'OPTIONS' && env['HTTP_ACCESS_CONTROL_REQUEST_METHOD']
            return [200, preflight_headers(env), ''] if allowed?(env)
            return [400, {}, '']
          end

          if allowed_origin?(env['HTTP_ORIGIN']) && allowed_method?(env['REQUEST_METHOD'])
            env['cors.headers'] = response_headers(env)
          end
        end

        super(env)
      end

      def post_process(env, status, headers, body)
        augmented_headers = headers.merge(env['cors.headers']) if env['cors.headers']
        [status, augmented_headers || headers, body]
      end

      private

        def allowed?(env)
          allowed_origin?(env['HTTP_ORIGIN']) &&
            allowed_method?(env['HTTP_ACCESS_CONTROL_REQUEST_METHOD'])
        end

        def allowed_origin?(origin)
          case @origin
          when Regexp
            @origin =~ origin
          when '*'
            true
          else
            origin == @origin || origin =~ %r(^https?://#{@origin})
          end
        end

        def allowed_method?(method)
          methods.include?(method.to_s.upcase)
        end

        def methods
          @methods.map { |m| m.to_s.upcase }
        end

        def preflight_headers(env)
          response_headers(env).merge(
            'Content-Type' => 'text/plain',
            'Access-Control-Allow-Headers' => env['HTTP_ACCESS_CONTROL_REQUEST_HEADERS'],
          )
        end

        def response_headers(env)
          {
            'Access-Control-Allow-Origin' => env['HTTP_ORIGIN'],
            'Access-Control-Allow-Methods' => methods.join(', '),
            'Access-Control-Max-Age' => @max_age.to_s
          }
        end
    end
  end
end
