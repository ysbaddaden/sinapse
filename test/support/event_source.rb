module Goliath
  module TestHelper
    class EventSourceHelper
      attr_reader :connection

      def initialize(url, request_data = {})
        @header = EM::Queue.new
        @queue = EM::Queue.new

        @connection = EM::HttpRequest.new(url).aget(request_data)

        @connection.errback do |e|
          if e.response_header.status >= 400
            EM.stop_event_loop
            raise "Error encountered during HTTP connection (#{e.response_header.status}): #{e}"
          end
        end

        @connection.callback { EM.stop_event_loop }
        @connection.headers { |h| @header.push(h) }
        @connection.stream { |m| @queue.push(m) }
      end

      def headers
        return @headers unless @headers.nil?

        fiber = Fiber.current
        @header.pop do |h|
          @headers = h
          fiber.resume(h)
        end
        Fiber.yield
      end

      def receive
        fiber = Fiber.current
        @queue.pop { |m| fiber.resume(m) }
        Fiber.yield
      end

      def close
        @connection.close
      end
    end

    def aget_request(request_data = {}, &blk)
      url = "http://localhost:#{@test_server_port}/"
      client = EventSourceHelper.new(url, request_data)
      blk.call(client) if blk
    end

    def sse_connect(query_params = nil, &blk)
      query_params ||= { query: { access_token: 'valid' } }

      with_api(Sinapse::Server, { verbose: true, log_stdout: true }) do |server|
        aget_request(query_params) do |client|
          begin
            blk.call(client) if blk
          ensure
            EM.stop_event_loop
            EM.stop # ensures that we don't leak the Goliath server on failed assertions
          end
        end
      end
    end
  end
end
