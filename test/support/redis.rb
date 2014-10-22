require 'msgpack'

module RedisTestHelper
  def redis
    @redis ||= Redis.new(driver: 'synchrony', url: Sinapse.config.redis_url)
  end

  def publish_until_received
    EM.next_tick do
      notify = lambda do
        EM.next_tick { notify.call if yield == 0 }
      end
      notify.call
    end
  end

  def wait_for_message(pattern)
    EM.synchrony do
      redis.psubscribe(pattern) do |on|
        on.pmessage do |key, channel, data|
          begin
            data = MessagePack.unpack(data)
          rescue MessagePack::MalformedFormatError
          end
          yield(channel, data)
          redis.punsubscribe
        end
      end
      EM.stop
    end
  end
end
