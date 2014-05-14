module Sinapse
  # TODO: #access_token to return the current user token (or generate one if missing)
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

    # Removes all channels at once.
    def clear
      channels.each { |channel| remove_channel(channel) }
    end

    # Removes all channels and clears authentication.
    def destroy
      channels.each { |channel| remove_channel(channel) }
      auth.clear
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
