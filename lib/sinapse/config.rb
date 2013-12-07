require 'active_support/core_ext/object/blank'

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

    private

      def default(name, default_value)
        if ENV[name.to_s].blank?
          default_value.to_s
        else
          ENV[name.to_s]
        end
      end
  end
end
