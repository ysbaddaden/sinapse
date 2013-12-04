require 'test_helper'

describe Sinapse::Server do
  include Goliath::TestHelper
  include RedisTestHelper

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
      connect(query: { access_token: '' }) do |conn|
        assert_equal 400, conn.response_header.status
      end
    end

    #it "won't authenticate with wrong token" do
    #  connect(query: { access_token: 'invalid' }) do |client|
    #    assert_equal 401, conn.response_header.status
    #  end
    #end
  end

  describe "events" do
    let(:channel_name) { 'sinapse' }

    it "must proxy published messages" do
      sse_connect do |client|
        client.receive # skips authentication message

        assert_equal 1, redis.publish(channel_name, "payload message")
        assert_equal "event: #{channel_name}\ndata: payload message\n\n", client.receive

        assert_equal 1, redis.publish(channel_name, "another message")
        assert_equal "event: #{channel_name}\ndata: another message\n\n", client.receive
      end
    end
  end
end
