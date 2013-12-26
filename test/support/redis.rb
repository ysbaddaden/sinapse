module RedisTestHelper
  def redis
    @redis ||= Redis.new(driver: 'synchrony', url: Sinapse.config[:url])
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
        on.pmessage do |key, channel, message|
          yield(channel, message)
          redis.punsubscribe
        end
      end
      EM.stop
    end
  end
end
