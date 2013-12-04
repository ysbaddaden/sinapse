$:.unshift File.expand_path("../../lib", File.realpath(__FILE__))

require 'bundler/setup'
Bundler.require(:default, :test)
require 'timeout'

Minitest::Reporters.use! # Minitest::Reporters::SpecReporter.new

class Minitest::Spec
  include Timeout

  def assert_event(data, event = channel_name)
    assert_equal "event: #{channel_name}\ndata: #{data}", read_event
  end

  def consume_response
    until conn.readline.strip.empty? do end
  end

  def read_response
    [read_status, read_headers]
  end

  def read_status
    conn.readline.rstrip
  end

  def read_headers
    headers = []
    until (line = conn.readline.strip).empty?
      headers << line.downcase.split(':').map(&:strip)
    end
    headers
  end

  def read_event
    timeout(2) do
      event = []
      until (line = conn.readline.strip).empty?
        event << line.rstrip
      end
      event.join("\n")
    end
  end
end
