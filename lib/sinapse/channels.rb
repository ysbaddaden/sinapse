module Sinapse
  # TODO: #clear to drop all channels at once
  # TODO: #destroy to drop the user token and all its channels at once
  class Channels < Struct.new(:record)
    def auth
      @auth ||= Authentication.new(record)
    end

    def channels
      Sinapse.redis { |redis| redis.smembers(key) }
    end

    def has_channel?(channel)
      Sinapse.redis { |redis| redis.sismember(key, channel_for(channel)) }
    end

    def add_channel(channel)
      Sinapse.redis do |redis|
        redis.sadd(key, channel_for(channel))
        redis.publish(key(:add), channel_for(channel))
      end
    end

    def remove_channel(channel)
      Sinapse.redis do |redis|
        redis.srem(key, channel_for(channel))
        redis.publish(key(:remove), channel_for(channel))
      end
    end

    def channel_for(record)
      record.is_a?(String) ? record : record.sinapse_channel
    end

    def key(extra = nil)
      key = "sinapse:channels:#{record.to_param}"
      key += ":#{extra}" if extra
      key
    end
  end
end
