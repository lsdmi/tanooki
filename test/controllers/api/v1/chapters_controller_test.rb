# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class ChaptersControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:user_two)
        @token, @secret = issue(%w[chapters:read chapters:write])
        FictionScanlator.create!(fiction: fictions(:eighteen), scanlator: scanlators(:two))
        @chapter = Api::Chapters::Create.call(
          user: @user, token: @token, fiction_id: fictions(:eighteen).id,
          params: { number: 21, title: 'Було', content: 'Текст чернетки.', scanlator_ids: [scanlators(:two).id] }
        ).chapter
      end

      teardown do
        Rails.cache.delete(Api::Limits.counter_key(:create, @user, Date.current))
      end

      test 'a missing token cannot update' do
        patch api_v1_chapter_path(@chapter.id), params: { title: 'Ні', version: 'x' }, as: :json

        assert_response :unauthorized
      end

      test 'another teams chapter is not found' do
        get api_v1_chapter_path(chapters(:one).id), headers: auth

        assert_response :not_found
        assert_equal 'not_found', response.parsed_body.dig('error', 'code')
      end

      test 'the owner updates a draft with the current version' do
        version = response_version
        patch api_v1_chapter_path(@chapter.id), params: { title: 'Стало', version: }, headers: auth, as: :json

        assert_response :success
        assert_equal 'Стало', response.parsed_body['title']
      end

      test 'a paragraph edit returns the new text and what was removed' do
        version = response_version
        markdown = response.parsed_body['paragraphs'].first['markdown']
        post paragraph_edits_api_v1_chapter_path(@chapter.id),
             params: { version:, edits: [{ n: 1, old: markdown, new: "Змінений\n\n![x](https://evil.test/a.png)" }] },
             headers: auth, as: :json

        assert_response :success
        assert_includes response.parsed_body['html'], 'Змінений'
        assert_includes response.parsed_body['sanitizer_changes'].join, 'evil.test'
      end

      private

      def issue(scopes)
        token = ApiToken.issue!(user: @user, name: 'Claude', scopes:)
        [token, token.secret]
      end

      def auth
        { 'Authorization' => "Bearer #{@secret}" }
      end

      def response_version
        get api_v1_chapter_path(@chapter.id), headers: auth
        response.parsed_body['version']
      end
    end

    class MineFictionsControllerTest < ActionDispatch::IntegrationTest
      test 'a member sees their fictions' do
        _token, secret = issue

        get fictions_api_v1_me_path, headers: { 'Authorization' => "Bearer #{secret}" }

        ids = response.parsed_body['fictions'].pluck('id')

        assert_response :success
        assert_equal [fictions(:eighteen).id], ids
      end

      test 'a missing token is unauthorized' do
        get fictions_api_v1_me_path

        assert_response :unauthorized
      end

      private

      def issue
        FictionScanlator.create!(fiction: fictions(:eighteen), scanlator: scanlators(:two))
        token = ApiToken.issue!(user: users(:user_two), name: 'Claude', scopes: %w[chapters:read])
        [token, token.secret]
      end
    end
  end
end
