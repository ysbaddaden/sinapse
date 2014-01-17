require 'test_helper'
require 'sinapse/cross_origin_resource_sharing'

describe "Sinapse::Rack::CrossOriginResourceSharing" do
  let(:app) { Minitest::Mock.new }

  describe "regular request" do
    it "calls app" do
      env = { 'REQUEST_METHOD' => 'POST' }
      app.expect(:call, [200, {}, ''], [env])
      assert_equal [200, {}, ''], cors(origin: '*').call(env)
      app.verify
    end
  end

  describe "preflight check" do
    let(:env) do
      { 'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'GET', 'REQUEST_METHOD' => 'OPTIONS' }
    end

    describe "when domain is *" do
      let(:domain) { %w(test.host example.com somewhere.org)[rand(0..2)] }

      it "allows any domain" do
        status, headers, body = cors(origin: '*')
          .call(env.merge('HTTP_ORIGIN' => "http://#{domain}"))

        assert_equal 200, status
        assert_equal 'text/plain', headers['Content-Type']
        assert_equal "http://#{domain}", headers['Access-Control-Allow-Origin']
        assert_nil headers['Access-Control-Allow-Headers']
        assert_empty body
      end
    end

    describe "when origin is a domain" do
      it "allows request for HTTP" do
        status, headers, _ = cors(origin: 'example.com')
          .call(env.merge('HTTP_ORIGIN' => 'http://example.com'))
        assert_equal 200, status
        assert_equal 'http://example.com', headers['Access-Control-Allow-Origin']
      end

      it "allows request for HTTPS" do
        status, headers, _ = cors(origin: 'example.com')
          .call(env.merge('HTTP_ORIGIN' => 'https://example.com'))
        assert_equal 200, status
        assert_equal 'https://example.com', headers['Access-Control-Allow-Origin']
      end

      it "refuses another domain" do
        status, headers, _ = cors(origin: 'example.com')
          .call(env.merge('HTTP_ORIGIN' => 'http://test.host'))
        assert_equal 400, status
        assert_nil headers['Access-Control-Allow-Origin']
      end
    end

    describe "when origin is a string" do
      it "allows specific origin" do
        status, headers, _ = cors(origin: 'http://example.com')
          .call(env.merge('HTTP_ORIGIN' => 'http://example.com'))
        assert_equal 200, status
        assert_equal 'http://example.com', headers['Access-Control-Allow-Origin']
      end

      it "refuses another origin" do
        status, headers, _ = cors(origin: 'https://example.com')
          .call(env.merge('HTTP_ORIGIN' => 'http://example.com'))
        assert_equal 400, status
        assert_nil headers['Access-Control-Allow-Origin']
      end
    end

    describe "when origin is a regexp" do
      let(:domain) { %w(example.com test.host)[rand(0..1)] }

      it "allows matching origin" do
        status, headers, _ = cors(origin: %r(^https?://(example\.com|test\.host)))
          .call(env.merge('HTTP_ORIGIN' => "http://#{domain}"))
        assert_equal 200, status
        assert_equal "http://#{domain}", headers['Access-Control-Allow-Origin']
      end

      it "refuses an origin that doesn't match" do
        status, headers, _ = cors(origin: %r(^http?://(example\.com|test\.host)))
          .call(env.merge('HTTP_ORIGIN' => 'http://somewhere.org'))
        assert_equal 400, status
        assert_nil headers['Access-Control-Allow-Origin']
      end
    end

    describe "methods" do
      let(:methods) { %w(GET POST DELETE) }
      let(:method) { methods[rand(0..2)] }

      it "accepts method" do
        status, headers, _ = cors(origin: '*', methods: methods).call(env.merge(
          'HTTP_ORIGIN' => "http://test.host",
          'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => method
        ))
        assert_equal 200, status
        assert_equal "http://test.host", headers['Access-Control-Allow-Origin']
        assert_equal 'GET, POST, DELETE', headers['Access-Control-Allow-Methods']
      end

      it "refuses method" do
        status, headers, _ = cors(origin: '*', methods: methods).call(env.merge(
          'HTTP_ORIGIN' => "http://test.host",
          'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'PATCH'
        ))
        assert_equal 400, status
        assert_nil headers['Access-Control-Allow-Origin']
        assert_nil headers['Access-Control-Allow-Methods']
      end
    end
  end

  describe "actual request" do
    it "adds headers when origin header is present" do
      env = {
        'HTTP_ORIGIN' => 'http://example.com',
        'REQUEST_METHOD' => 'POST'
      }
      app.expect(:call, [200, {}, ''], [env])
      status, headers, body = cors(origin: '*', methods: %w(POST)).call(env)
      app.verify

      assert_equal 200, status
      assert_equal '', body
      assert_equal 'http://example.com', headers['Access-Control-Allow-Origin']
      assert_equal 'POST', headers['Access-Control-Allow-Methods']
    end

    it "skips headers when origin is refused" do
      env = {
        'HTTP_ORIGIN' => 'http://test.com',
        'REQUEST_METHOD' => 'POST'
      }
      app.expect(:call, [200, {}, ''], [env])
      status, headers, _ = cors(origin: 'example.com', methods: %w(POST)).call(env)
      app.verify

      assert_equal 200, status
      assert_nil headers['Access-Control-Allow-Origin']
      assert_nil headers['Access-Control-Allow-Methods']
    end

    it "skips headers when method is refused" do
      env = {
        'HTTP_ORIGIN' => 'http://test.host',
        'REQUEST_METHOD' => 'GET'
      }
      app.expect(:call, [200, {}, ''], [env])
      status, headers, _ = cors(origin: 'test.host', methods: %w(POST)).call(env)
      app.verify

      assert_equal 200, status
      assert_nil headers['Access-Control-Allow-Origin']
      assert_nil headers['Access-Control-Allow-Methods']
    end
  end

  def cors(options = {})
    Sinapse::Rack::CrossOriginResourceSharing.new(app, options)
  end
end
