require 'sinapse/version'
require 'sinapse/authentication'
require 'sinapse/channels'
require 'sinapse/config'
require 'sinapse/publishable'
require 'connection_pool'
require 'redis'
require 'hiredis'

module Sinapse
  def sinapse
    @sinapse ||= Sinapse::Channels.new(self)
  end

  def self.redis(&block)
    raise ArgumentError, "requires a block" unless block
    @redis ||= ConnectionPool.new(config.redis_pool_options) { Redis.new(url: config.redis_url) }
    @redis.with(&block)
  end

  def self.redis=(redis)
    raise ArgumentError, "requires a ConnectionPool" unless redis.kind_of?(ConnectionPool)
    @redis = redis
  end
end
