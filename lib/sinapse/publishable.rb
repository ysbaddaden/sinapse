require 'active_support/core_ext/string/inflections'

module Sinapse
  module Publishable
    def self.included(klass)
      klass.__send__ :alias_method, :publish, :sinapse_publish unless klass.respond_to?(:publish)
    end

    def sinapse_publish(message)
      Sinapse.redis { |redis| redis.publish(sinapse_channel, message) }
    end

    def sinapse_channel
      [self.class.name.underscore.singularize, self.to_param].join(':')
    end
  end
end
