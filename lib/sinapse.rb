require 'sinapse/version'
require 'sinapse/authentication'
require 'sinapse/channels'
require 'sinapse/publishable'

module Sinapse
  def sinapse
    @sinapse ||= Sinapse::Channels.new(self)
  end

  class << self
    def redis(&block)
      raise ArgumentError, "requires a block" unless block
      @redis ||= ConnectionPool.new(pool_options) { Redis.new(url: config[:url]) }
      @redis.with(&block)
    end

    def redis=(redis)
      raise ArgumentError, "requires a ConnectionPool" unless redis.kind_of?(ConnectionPool)
      @redis = redis
    end

    def config
      @config ||= {
        size: 5,
        timeout: 5,
        url: 'redis://localhost:6379/0'
      }
    end

    def config=(options)
      @config = config.merge(options.symbolize_keys)
    end

    def pool_options
      @pool_options ||= { size: config[:size], timeout: config[:timeout] }
    end
  end
end
