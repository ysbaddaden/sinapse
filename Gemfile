source 'https://rubygems.org'

gem 'goliath'
gem 'redis'
gem 'hiredis'
gem 'connection_pool'
gem 'activesupport', require: false

platform :rbx do
  gem 'rubysl-base64'
  gem 'rubysl-singleton'
  gem 'rubysl-mutex_m', group: [:test]
  gem 'rubysl-prettyprint', group: [:development]
end

group :test do
  gem 'rake'
  gem 'em-http-request'
  gem 'minitest', require: 'minitest/autorun'
  gem 'minitest-reporters'
end

