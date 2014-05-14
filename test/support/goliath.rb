require 'goliath/test_helper'

Goliath.env = RACK_ENV

module Goliath
  module TestHelper
    def connect(query_params = nil, &blk)
      with_api(Sinapse::Server) do
        get_request(query_params, &blk)
      end
    end

    def ws_connect(token, &blk)
      with_api(Sinapse::Server) do
        ws_client_connect("/?access_token=#{token}", &blk)
      end
    end
  end
end
