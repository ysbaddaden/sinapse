module Sinapse
  class Config
    attr_accessor :retry, :keep_alive, :cors_origin, :channel_event
    attr_accessor :redis_url, :redis_pool_options

    def initialize
      self.retry = ENV.fetch('SINAPSE_RETRY', 5) * 1000
      self.keep_alive = ENV.fetch('SINAPSE_KEEP_ALIVE', 15)
      self.cors_origin = ENV.fetch('SINAPSE_CORS_ORIGIN', '*')
      self.channel_event = !ENV["SINAPSE_CHANNEL_EVENT"].nil?

      self.redis_url = ENV.fetch('REDIS_URL', 'redis://localhost:6379/0')
      self.redis_pool_options = { size: 5, timeout: 5 }
    end
  end

  def self.config
    @@config ||= Config.new
  end
end
