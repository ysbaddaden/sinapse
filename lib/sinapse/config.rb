require 'active_support/core_ext/object/blank'

module Sinapse
  module Config
    def self.retry
      @retry ||= default(:SSE_RETRY, 5).to_i * 1000
    end

    def self.ping
      @ping ||= default(:SSE_PING, 15).to_i
    end

    def self.access_control_allow_origin
      @access_control_allow_origin ||= default(:SSE_ACCESS_CONTROL_ALLOW_ORIGIN, '*')
    end

    private

      def self.default(name, default)
        ENV[name.to_s].present? ? ENV[name.to_s] : default
      end
  end
end
