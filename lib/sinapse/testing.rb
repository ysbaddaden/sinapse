module Sinapse
  def self.messages
    @@messages ||= []
  end

  module Publishable
    alias_method :sinapse_publish_orig, :sinapse_publish

    def sinapse_publish(message, options = {})
      if Sinapse::Testing.enabled?
        Sinapse.messages << { channel: sinapse_channel, message: message, event: options[:event] }
      else
        sinapse_publish_orig(message, options)
      end
    end
  end

  module Testing
    def self.enabled?
      !!@@enabled
    end

    def self.enable!
      @@enabled = true
    end

    def self.disable!
      @@enabled = false
    end
  end

  module TestHelper
    def self.included(klass)
      if klass.respond_to?(:before)
        klass.before { Sinapse.messages.clear }
      elsif klass.respond_to?(:setup)
        klass.setup { Sinapse.messages.clear } rescue nil
      end
    end

    def assert_publishes(number = 1)
      if block_given?
        original_count = Sinapse.messages.size
        yield
        new_count = Sinapse.messages.size
        assert_equal original_count + number, new_count, "#{number} messages expected, but #{new_count - original_count} were sent"
      else
        assert_equal number, Sinapse.messages.size
      end
    end

    def refute_publishes(&block)
      assert_publishes(0, &block)
    end
  end
end
