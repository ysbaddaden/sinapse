$:.unshift File.expand_path("../../lib", File.realpath(__FILE__))
RACK_ENV ||= ENV['RACK_ENV'] ||= 'test'

require 'bundler/setup'
require 'minitest/autorun'
require 'minitest/reporters'
require 'sinapse'
require 'sinapse/server'

require_relative 'support/redis'
require_relative 'support/timeout'
require_relative 'support/goliath'
require_relative 'support/event_source'

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

class User < Struct.new(:id)
  include Sinapse
  def to_param; id.to_s; end
end

class Admin < Struct.new(:id)
  include Sinapse
  def to_param; id.to_s; end
end

class Room < Struct.new(:id)
  include Sinapse::Publishable
  def to_param; id.to_s; end
end

