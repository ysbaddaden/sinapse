module Sinapse
  module Config
    extend self

    def retry
      default(:SINAPSE_RETRY, 5).to_i * 1000
    end

    def keep_alive
      default(:SINAPSE_KEEP_ALIVE, 15).to_i
    end

    def cors_origin
      default(:SINAPSE_CORS_ORIGIN, '*')
    end

    def channel_event
      !ENV["SINAPSE_CHANNEL_EVENT"].nil?
    end

    private

      def default(name, default_value)
        if ENV.has_key?(name.to_s)
          ENV[name.to_s]
        else
          default_value.to_s
        end
      end
  end
end
