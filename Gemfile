source 'https://rubygems.org'

gemspec

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
