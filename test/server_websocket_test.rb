require 'test_helper'
require 'sinapse/server'

describe "Sinapse::Server::WebSocket" do
  include Goliath::TestHelper
  include RedisTestHelper

  before do
    EM.synchrony do
      redis.set('sinapse:tokens:valid', '1')
      redis.set('sinapse:tokens:empty', '2')
      redis.sadd('sinapse:channels:1', 'user:1')
      redis.sadd('sinapse:channels:1', 'room:2')
      redis.sadd('sinapse:channels:1', 'room:4')
      EM.stop_event_loop
    end
  end

  after do
    EM.synchrony do
      redis.del('sinapse:tokens:valid')
      redis.del('sinapse:tokens:empty')
      redis.del('sinapse:channels:1')
      EM.stop_event_loop
    end
  end

  describe "authentication" do
    it "sends an ok message on success" do
      ws_connect("valid") do |client|
        assert_equal "authentication: ok", client.receive.data
      end
    end

    it "fails handshake with 401 status code for unknown token" do
      assert_raises(WebSocket::Error::Handshake::InvalidStatusCode) do
        ws_connect("invalid")
      end
    end
  end

  describe "push" do
    let(:channel_name) { 'user:1' }

    it "proxies published messages" do
      ws_connect("valid") do |client|
        client.receive

        assert_equal 1, publish(channel_name, "payload message")
        assert_equal 'payload message', client.receive.data

        assert_equal 1, publish(channel_name, "another message")
        assert_equal 'another message', client.receive.data
      end
    end

    it "won't set channel name as event type" do
      Sinapse.config.stub(:channel_event, true) do
        ws_connect("valid") do |client|
          client.receive
          assert_equal 1, publish(channel_name, "payload message")
          assert_equal("payload message", client.receive.data)
        end
      end
    end

    it "discards specified event type" do
      ws_connect("valid") do |client|
        client.receive
        assert_equal 1, publish(channel_name, "payload", "hello:world")
        assert_equal("payload", client.receive.data)
      end
    end
  end

  it "periodically pings the socket" do
    Sinapse.config.stub(:keep_alive, 0.001) do
      ws_connect("valid") do |client|
        client.receive # skip authentication
        assert_equal :ping, client.receive.type
        assert_equal :ping, client.receive.type
        assert_equal :ping, client.receive.type
      end
    end
  end
end
