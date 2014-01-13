require 'test_helper'

describe "Sinapse::Authentication" do
  after do
    Sinapse.redis do |redis|
      redis.keys('sinapse:*').each { |key| redis.del(key) }
    end
  end

  let(:user) { User.new(rand(1..100)) }
  let(:auth) { user.sinapse.auth }

  it "key" do
    assert_equal "sinapse:User:1", User.new(1).sinapse.auth.key
    assert_equal "sinapse:Admin:456", Admin.new(456).sinapse.auth.key
  end

  describe "generate" do
    it "must generate token" do
      Sinapse.stub(:generate_token, 'valid') do
        auth.generate

        Sinapse.redis do |redis|
          assert_equal 'valid', redis.get(auth.key)
          assert_equal user.to_param, redis.get(auth.token_key('valid'))
        end
      end
    end

    it "won't use an existing token" do
      tokens = ['first', 'first', 'second']

      Sinapse.stub(:generate_token, lambda { tokens.shift }) do
        User.new(2).sinapse.auth.generate
        auth.generate

        Sinapse.redis do |redis|
          assert_equal 'second', redis.get(auth.key)
        end
      end
    end
  end

  it "clear" do
    Sinapse.stub(:generate_token, 'a1b2c3d4e5f6') do
      auth.generate
      auth.clear

      Sinapse.redis do |redis|
        assert_nil redis.get(auth.key)
        assert_nil redis.get(auth.token_key('a1b2c3d4e5f6'))
      end
    end
  end

  it "reset" do
    tokens = ['first', 'second']

    Sinapse.stub(:generate_token, lambda { tokens.shift }) do
      auth.generate
      auth.reset

      Sinapse.redis do |redis|
        assert_equal 'second', redis.get(auth.key)
        assert_equal user.to_param, redis.get(auth.token_key('second'))
      end
    end
  end
end
