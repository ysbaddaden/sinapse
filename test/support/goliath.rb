require 'goliath/test_helper'

module Goliath
  module TestHelper
    def connect(query_params = nil, &blk)
      with_api(Sinapse::Server) do
        get_request(query_params, &blk)
      end
    end
  end
end
