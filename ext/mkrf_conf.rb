# http://en.wikibooks.org/wiki/Ruby_Programming/RubyGems#How_to_install_different_versions_of_gems_depending_on_which_version_of_ruby_the_installee_is_using
require 'rubygems'
require 'rubygems/command.rb'
require 'rubygems/dependency_installer.rb'

begin
  Gem::Command.build_args = ARGV
rescue NoMethodError
end

inst = Gem::DependencyInstaller.new

begin
  if RUBY_ENGINE == "rbx"
    inst.install "rubysl-securerandom"
    #inst.install "rubysl-base64"
  end
rescue
  exit 1
end

exit 0
