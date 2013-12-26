$:.unshift File.expand_path("../../lib", File.realpath(__FILE__))
RACK_ENV ||= ENV['RACK_ENV'] ||= 'test'

require 'bundler/setup'
Bundler.require(:default, RACK_ENV)
Goliath.env = RACK_ENV

require 'sinapse'
require_relative 'support/event_source'
require_relative 'support/redis'
require_relative 'support/goliath'

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

class User < Struct.new(:id)
  include Sinapse

  def to_param; id.to_s; end
end

class Room < Struct.new(:id)
  include Sinapse::Publishable

  def to_param; id.to_s; end
end

