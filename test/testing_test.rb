require "test_helper"
require "sinapse/testing"

Sinapse::Testing.disable!

describe "Sinapse::Testing" do
  include Sinapse::TestHelper

  before { Sinapse::Testing.enable! }
  after { Sinapse::Testing.disable! }

  let(:room) { Room.new(1) }

  it "assert_publishes" do
    assert_publishes(1) do
      room.publish('hello room 1', event: "event_name")
    end

    assert_equal room.sinapse_channel, Sinapse.messages.last[:channel]
    assert_equal "event_name", Sinapse.messages.last[:event]
    assert_equal "hello room 1", Sinapse.messages.last[:message]

    assert_raises Minitest::Assertion do
      assert_publishes {}
    end
  end

  it "refute_publishes" do
    refute_publishes {}

    assert_raises Minitest::Assertion do
      refute_publishes do
        room.publish('hello room 1', event: "event_name")
      end
    end
  end
end
