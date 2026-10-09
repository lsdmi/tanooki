# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class ChapterImagesControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:user_two)
        @token = ApiToken.issue!(user: @user, name: 'Images', scopes: %w[chapters:read images:write])
        @secret = @token.secret
      end

      test 'a file is stored and the url comes back' do
        assert_difference -> { ActiveStorage::Blob.where(service_name: ::Chapters::Images.service_name).count } do
          post api_v1_chapter_images_path, params: { file: valid_cover_upload }, headers: auth
        end

        assert_response :created
        assert_predicate response.parsed_body['url'], :present?
      end

      test 'a url is fetched and stored' do
        bytes = File.binread(CoverUploadHelper::VALID_COVER_PATH)
        UrlFetch.stub(:bytes, bytes) do
          post api_v1_chapter_images_path,
               params: { url: 'https://cdn.example/a.webp' }, headers: auth, as: :json
        end

        assert_response :created
        assert_predicate response.parsed_body['url'], :present?
      end

      test 'a private url is refused' do
        post api_v1_chapter_images_path, params: { url: 'http://169.254.169.254/latest' }, headers: auth, as: :json

        assert_response :unprocessable_content
        assert_equal 'unsafe_url', response.parsed_body.dig('error', 'code')
      end

      test 'a missing file is refused' do
        post api_v1_chapter_images_path, headers: auth, as: :json

        assert_response :unprocessable_content
        assert_equal 'image_missing', response.parsed_body.dig('error', 'code')
      end

      test 'the images scope is required' do
        token = ApiToken.issue!(user: @user, name: 'Drafts', scopes: %w[chapters:write])

        post api_v1_chapter_images_path, headers: { 'Authorization' => "Bearer #{token.secret}" }, as: :json

        assert_response :forbidden
      end

      test 'a guest is unauthorized' do
        post api_v1_chapter_images_path, as: :json

        assert_response :unauthorized
      end

      private

      def auth
        { 'Authorization' => "Bearer #{@secret}" }
      end
    end
  end
end
