# -*- encoding: utf-8 -*-
require File.expand_path('../lib/sinapse/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Julien Portalier"]
  gem.email         = ["julien@portalier.com"]
  gem.description   = gem.summary = "An EventSource push service for Ruby"
  gem.homepage      = "http://github.com/ysbaddaden/sinapse"
  gem.license       = "MIT"

  gem.executables   = ['sinapse']
  gem.files         = `git ls-files | grep -Ev '^example'`.split("\n")
  gem.test_files    = `git ls-files -- test/*`.split("\n")
  gem.name          = "sinapse"
  gem.require_paths = ["lib"]
  gem.version       = Sinapse::VERSION::STRING

  gem.cert_chain    = ['certs/ysbaddaden.pem']
  gem.signing_key   = File.expand_path('~/.ssh/gem-private_key.pem') if $0 =~ /gem\z/

  gem.add_dependency 'goliath', '>= 1.0.4'
  gem.add_dependency 'redis', '>= 3.0.6'
  gem.add_dependency 'hiredis'
  gem.add_dependency 'connection_pool'
  gem.add_dependency 'msgpack', '>= 0.5.0'
  gem.add_dependency 'activesupport', '>= 3.0.0'

  gem.add_development_dependency 'bundler'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'em-http-request'
  gem.add_development_dependency 'em-websocket-client'
  gem.add_development_dependency 'minitest', '>= 5.2.0'
  gem.add_development_dependency 'minitest-reporters'
end
