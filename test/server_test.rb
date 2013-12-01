require 'test_helper'

Sinapse::Server.new('localhost', 9999)

describe Sinapse::Server do
  let(:channel_name) { 'sinapse' }
  let(:params) { "channel=#{channel_name}&user=julien&token=valid" }
  let(:redis) { @redis = Redis.new(driver: 'celluloid') }

  let(:conn) do
    @conn = TCPSocket.new('localhost', 9999)
    @conn.write "GET /?#{params} HTTP/1.1\r\nHost: sinapse.example.com\r\n\r\n"
    @conn
  end

  after do
    conn.close if @conn
    redis.client.disconnect if @redis
  end

  describe "connection" do
    it "must connect" do
      assert_match(/\AHTTP\/1\.1 \d+ .+/, read_status)
    end

    it "must be an event-source stream" do
      _, headers = read_response
      assert_includes headers, ['content-type', 'text/event-stream']
      assert_includes headers, ['connection', 'close']
      refute_includes headers.flatten, 'content-length'
    end
  end

  describe "authentication" do
    describe "success" do
      it "must return ok status" do
        assert_match(/200 OK/i, read_status)
      end

      it "must return authentication event" do
        consume_response
        assert_equal "retry: 5000\nid: 0\nevent: authentication\ndata: ok", read_event
      end

      it "won't close the socket" do
        assert conn.readpartial(4096)
        refute conn.closed?
      end
    end

    #describe "failure" do
    #  let(:params) { "channel=#{channel_name}&user=julien&token=valid" }

    #  it "must return unauthorized status" do
    #    assert_match(/401 UNAUTHORIZED/i, read_status)
    #  end

    #  it "must close the socket" do
    #    assert conn.readpartial(4096)
    #    assert conn.closed?
    #  end
    #end
  end

  describe "events" do
    it "must proxy published message" do
      consume_response
      read_event

      redis.publish(channel_name, "payload message")
      assert_event("payload message", channel_name)
    end
  end
end
