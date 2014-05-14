source 'https://rubygems.org'

gem 'goliath'
gem 'redis'
gem 'hiredis'
gem 'connection_pool'
gem 'msgpack'
gem 'activesupport', require: false

platform :rbx do
  gem 'rubysl-securerandom'

  group :development do
    gem 'rubysl-prettyprint'
  end

  group :test do
    gem 'rubysl-singleton'  # required by rake
    gem 'rubysl-base64'     # required by em-http-request
    gem 'rubysl-mutex_m'    # required by minitest 5.2
  end
end

group :test do
  gem 'rake'
  gem 'em-http-request'
  gem 'minitest', require: 'minitest/autorun'
  gem 'minitest-reporters'
end
