require 'timeout'

class Minitest::Spec
  def self.it(desc = 'anonymous', &block) # :nodoc:
    return super unless block
    super(desc) { Timeout.timeout(2) { self.instance_eval(&block) } }
  end
end
