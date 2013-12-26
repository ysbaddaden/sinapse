require 'active_support/core_ext/string/inflections'

module Sinapse
  module Publishable
    def publish(message)
      Sinapse.redis { |redis| redis.publish(sinapse_channel, message) }
    end

    def sinapse_channel
      [self.class.name.underscore.singularize, self.to_param].join(':')
    end
  end
end
