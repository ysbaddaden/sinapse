require 'securerandom'

module Sinapse
  def self.generate_token
    SecureRandom.urlsafe_base64(64)
  end

  class Authentication < Struct.new(:record)
    def reset
      clear
      generate
    end

    def generate
      Sinapse.redis do |redis|
        loop do
          token = Sinapse.generate_token
          if redis.setnx(token_key(token), record.to_param)
            redis.set(key, token)
            return token
          end
        end
      end
    end

    def clear
      Sinapse.redis do |redis|
        if token = redis.get(key)
          redis.del(token_key(token))
          redis.del(key)
        end
      end
    end

    def token_key(token)
      "sinapse:tokens:#{token}"
    end

    def key
      "sinapse:#{record.class.name}:#{record.to_param}"
    end
  end
end
