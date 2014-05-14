require 'test_helper'

describe "Sinapse::Publishable" do
  include RedisTestHelper

  let(:room) { Room.new(1) }

  it "sinapse_channel" do
    assert_equal 'room:1', Room.new(1).sinapse_channel
    assert_equal 'room:83', Room.new(83).sinapse_channel
  end

  it "publish" do
    EM.run do
      wait_for_message('room:*') do |channel, message|
        assert_equal room.sinapse_channel, channel
        assert_equal 'hello room 1', message
      end
      publish_until_received { room.publish('hello room 1') }
    end
  end

  it "publish with event type" do
    EM.run do
      wait_for_message('room:*') do |channel, message|
        assert_equal room.sinapse_channel, channel
        assert_equal ['hello', 'hello room 1'], message
      end
      publish_until_received { room.publish('hello room 1', event: 'hello') }
    end
  end
end
