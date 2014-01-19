module Sinapse
  def self.version
    Gem::Version.new File.read(File.expand_path('../../../VERSION', __FILE__))
  end

  module VERSION
    MAJOR, MINOR, TINY, PRE = Sinapse.version.segments
    STRING = Sinapse.version.to_s
  end
end
