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

      test 'the description mentions catalog without body text' do
        get '/api/v1/openapi.json'
        info = response.parsed_body.dig('info', 'description')

        assert_match(/без тексту/, info)
        assert_match(/version/, info)
      end

      test 'list and batch paths expose catalog vs body params' do
        get '/api/v1/openapi.json'
        list = response.parsed_body.dig('paths', '/fictions/{fiction_id}/chapters', 'get')
        batch = response.parsed_body.dig('paths', '/fictions/{fiction_id}/chapters/batch', 'get')

        assert_equal 'Каталог розділів без тексту', list['summary']
        assert(batch['parameters'].any? { |param| param['name'] == 'body' })
      end

      test 'paragraph_edits describes in-place text edits' do
        get '/api/v1/openapi.json'
        edits = response.parsed_body.dig('paths', '/chapters/{id}/paragraph_edits', 'post')

        assert_equal '1.2.0', response.parsed_body.dig('info', 'version')
        assert_match(/стилі й примітки/, edits['description'])
      end
    end
  end
end
