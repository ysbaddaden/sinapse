$:.unshift File.expand_path("../../lib", File.realpath(__FILE__))
RACK_ENV ||= ENV['RACK_ENV'] ||= 'test'

require 'bundler/setup'
Bundler.require(:default, RACK_ENV)
Goliath.env = RACK_ENV

require 'sinapse'
require 'goliath/test_helper'
require_relative 'support/event_source'

Minitest::Reporters.use! # Minitest::Reporters::SpecReporter.new

module RedisTestHelper
  def redis
    @redis ||= Redis.new
  end
end

module Goliath
  module TestHelper
    def connect(query_params = nil, &blk)
      with_api(Sinapse::Server) do
        get_request(query_params, &blk)
      end
    end
  end
end
