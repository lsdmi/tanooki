# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class OpenapiControllerTest < ActionDispatch::IntegrationTest
      test 'the description is public' do
        get '/api/v1/openapi.json'

        assert_response :success
        assert_equal '3.1.0', response.parsed_body['openapi']
        assert_includes response.parsed_body['paths'].keys, '/chapter_images'
      end
    end
  end
end
