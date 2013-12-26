require 'test_helper'
require 'sinapse/server'

describe Sinapse::Server do
  include Goliath::TestHelper
  include RedisTestHelper

  before do
    EM.synchrony do
      redis.set('sinapse:token:valid', '1')
      redis.set('sinapse:token:empty', '2')
      redis.sadd('sinapse:channels:1', 'user:1')
      redis.sadd('sinapse:channels:1', 'room:2')
      redis.sadd('sinapse:channels:1', 'room:4')
      EM.stop_event_loop
    end
  end

  after do
    EM.synchrony do
      redis.del('sinapse:token:valid')
      redis.del('sinapse:token:empty')
      redis.del('sinapse:channels:1')
      EM.stop_event_loop
    end
  end

  describe "authentication" do
    it "returns an event-stream on success" do
      sse_connect do |client|
        assert_equal '*', client.headers['ACCESS_CONTROL_ALLOW_ORIGIN']
        assert_equal 'close', client.headers['CONNECTION']
        assert_equal 'text/event-stream', client.headers['CONTENT_TYPE']
        assert_equal "retry: 5000\nevent: authentication\ndata: ok\n\n", client.receive
      end
    end

    it "won't authenticate without token" do
      connect(query: { access_token: '' }) do |client|
        assert_equal 400, client.response_header.status
      end
    end

    it "won't authenticate with unknown token" do
      connect(query: { access_token: 'invalid' }) do |client|
        assert_equal 401, client.response_header.status
      end rescue LocalJumpError
    end

    it "won't authenticate when user has no channels" do
      connect(query: { access_token: 'empty' }) do |client|
        assert_equal 401, client.response_header.status
      end rescue LocalJumpError
    end
  end

  describe "pub/sub" do
    let(:channel_name) { 'user:1' }

    it "proxies published messages" do
      sse_connect do |client|
        client.receive # skips authentication message

        assert_equal 1, redis.publish(channel_name, "payload message")
        assert_equal "event: #{channel_name}\ndata: payload message\n\n", client.receive

        assert_equal 1, redis.publish(channel_name, "another message")
        assert_equal "event: #{channel_name}\ndata: another message\n\n", client.receive
      end
    end

    it "disconnects from server on connection close" do
      sse_connect do |client|
        client.close
        EM.synchrony { assert_equal 0, redis.publish(channel_name, "message") }
      end
    end

    it "updates subscriptions when the list changes" do
      sse_connect do |client|
        client.receive

        redis.srem('sinapse:channels:1', 'room:2')
        redis.sadd('sinapse:channels:1', 'room:5')
        redis.publish('sinapse:channels:1', JSON.dump(redis.smembers('sinapse:channels:1')))

        assert_equal 1, redis.publish('room:4', "message for room 4")
        assert_equal "event: room:4\ndata: message for room 4\n\n", client.receive

        assert_equal 1, redis.publish('room:5', "message for room 5")
        assert_equal "event: room:5\ndata: message for room 5\n\n", client.receive

        assert_equal 0, redis.publish('room:2', "message for room 2")
      end
    end
  end

  describe "config" do
    before do
      ENV['SINAPSE_CORS_ORIGIN'] = 'example.com'
      ENV['SINAPSE_RETRY'] = '12'
    end

    after do
      ENV['SINAPSE_CORS_ORIGIN'] = nil
      ENV['SINAPSE_RETRY'] = nil
    end

    it "uses the config" do
      sse_connect do |client|
        assert_equal 'example.com', client.headers['ACCESS_CONTROL_ALLOW_ORIGIN']
        assert_match /retry: 12000\n/, client.receive
      end
    end
  end

  describe "keep alive" do
    before { ENV['SINAPSE_KEEP_ALIVE'] = '0.001' }
    after  { ENV['SINAPSE_KEEP_ALIVE'] = nil }

    it "periodically sends a comment" do
      sse_connect do |client|
        client.receive # skips authentication message

        assert_equal ":\n", client.receive
        assert_equal ":\n", client.receive
        assert_equal ":\n", client.receive
      end
    end
  end
end
