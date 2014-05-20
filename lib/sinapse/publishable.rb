require 'active_support/core_ext/string/inflections'
require 'msgpack'

module Sinapse
  module Publishable
    def sinapse_publish(message, options = nil)
      data = Publishable.pack(message, options)
      Sinapse.redis { |redis| redis.publish(sinapse_channel, data) }
    end

    alias_method :publish, :sinapse_publish

    def sinapse_channel
      [self.class.name.underscore.singularize, self.to_param].join(':')
    end

    private

      def self.pack(message, options)
        data = options.is_a?(Hash) && options[:event] ? [options[:event].to_s, message.to_s] : message.to_s
        MessagePack.pack(data)
      end
  end
end
