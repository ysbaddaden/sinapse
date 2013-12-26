require 'test_helper'

describe "Sinapse::Channels" do
  include RedisTestHelper

  before do
    Sinapse.redis do |redis|
      redis.sadd 'sinapse:channels:1', 'room:1'
      redis.sadd 'sinapse:channels:1', 'room:83'
    end
  end

  after do
    Sinapse.redis { |redis| redis.del 'sinapse:channels:1' }
  end

  let(:user) { User.new(1) }
  let(:room) { Room.new(1) }

  it "key" do
    assert_equal "sinapse:channels:1", User.new(1).sinapse.key
    assert_equal "sinapse:channels:345", User.new(345).sinapse.key
    assert_equal "sinapse:channels:345:add", User.new(345).sinapse.key(:add)
    assert_equal "sinapse:channels:345:remove", User.new(345).sinapse.key(:remove)
  end

  describe "channel_for" do
    it "accepts a string" do
      assert_equal 'room:1', user.sinapse.channel_for('room:1')
      assert_equal 'room:876', user.sinapse.channel_for('room:876')
    end

    it "accepts a record" do
      assert_equal 'room:1', user.sinapse.channel_for(Room.new(1))
      assert_equal 'room:4321', user.sinapse.channel_for(Room.new(4321))
    end
  end

  it "channels" do
    assert_equal ['room:1', 'room:83'], user.sinapse.channels.sort
    assert_equal [], User.new(2).sinapse.channels
  end

  it "has_channel?" do
    assert user.sinapse.has_channel?(room)
    refute user.sinapse.has_channel?('room:2')
    refute User.new(2).sinapse.has_channel?(room)
  end

  describe "add_channel" do
    let(:room) { Room.new(12345) }

    it "adds channel to the list" do
      user.sinapse.add_channel(room)
      assert user.sinapse.has_channel?(room)
    end

    it "publishes a message" do
      EM.run do
        wait_for_message('sinapse:channels:*') do |channel, message|
          assert_equal user.sinapse.key(:add), channel
          assert_equal room.sinapse_channel, message
        end
        publish_until_received { user.sinapse.add_channel(room) }
      end
    end
  end

  describe "remove_channel" do
    it "removes channel from the list" do
      user.sinapse.remove_channel(room)
      refute user.sinapse.has_channel?(room)
    end

    it "publishes a message" do
      EM.run do
        wait_for_message('sinapse:channels:*') do |channel, message|
          assert_equal user.sinapse.key(:remove), channel
          assert_equal room.sinapse_channel, message
        end
        publish_until_received { user.sinapse.remove_channel(room) }
      end
    end
  end
end
