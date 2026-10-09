# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class FictionChaptersControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:user_two)
        @token, @secret = issue(@user, %w[chapters:read chapters:write])
        @fiction = fictions(:eighteen)
        FictionScanlator.create!(fiction: @fiction, scanlator: scanlators(:two))
      end

      teardown do
        Rails.cache.delete(Api::Limits.counter_key(:create, @user, Date.current))
      end

      test 'a missing or wrong token is unauthorized' do
        statuses = [
          get(api_v1_fiction_chapters_path(@fiction)),
          post(api_v1_fiction_chapters_path(@fiction), params: draft_body, as: :json),
          get(api_v1_fiction_chapters_path(@fiction), headers: { 'Authorization' => 'Bearer baka_nope' })
        ]

        assert_equal [401, 401, 401], statuses
      end

      test 'a member lists and reads a chapter just created' do
        post api_v1_fiction_chapters_path(@fiction), params: draft_body, headers: auth, as: :json
        chapter_id = response.parsed_body['id']

        assert_response :created

        get api_v1_chapter_path(chapter_id), headers: auth

        assert_response :success
        assert_equal chapter_id, response.parsed_body['id']
      end

      test 'another teams fiction is not found' do
        get api_v1_fiction_chapters_path(fictions(:one)), headers: auth

        assert_response :not_found
        assert_equal 'not_found', response.parsed_body.dig('error', 'code')
      end

      test 'publishing without the scope is forbidden' do
        post api_v1_fiction_chapters_path(@fiction),
             params: draft_body.merge(status: 'published', content: 'а' * 500),
             headers: auth, as: :json

        assert_response :forbidden
        assert_equal 'publish_scope', response.parsed_body.dig('error', 'code')
      end

      test 'a duplicate number for the same team conflicts' do
        post api_v1_fiction_chapters_path(@fiction), params: draft_body.merge(number: 4), headers: auth, as: :json
        post api_v1_fiction_chapters_path(@fiction),
             params: draft_body.merge(number: 4, title: 'Ще'), headers: auth, as: :json

        assert_response :conflict
        assert_equal 'conflict', response.parsed_body.dig('error', 'code')
      end

      test 'another teams number does not conflict' do
        post api_v1_fiction_chapters_path(fictions(:one)),
             params: draft_body.merge(number: chapters(:one).number), headers: auth, as: :json

        assert_response :created
        assert_equal chapters(:one).number.to_i, response.parsed_body['number']
      end

      test 'short published content and a past date are readable errors' do
        _token, secret = issue(@user, %w[chapters:read chapters:write chapters:publish])
        headers = { 'Authorization' => "Bearer #{secret}" }
        post api_v1_fiction_chapters_path(@fiction),
             params: draft_body.merge(status: 'published', content: 'коротко'), headers:, as: :json

        assert_response :unprocessable_entity
        assert_match(/коротк/, response.parsed_body.dig('error', 'details', 'content').join)

        post api_v1_fiction_chapters_path(@fiction),
             params: draft_body.merge(status: 'published', content: 'а' * 500, published_at: 2.days.ago.iso8601),
             headers:, as: :json

        assert_match(/минул/, response.parsed_body.dig('error', 'details', 'published_at').join)
      end

      test 'the same idempotency key returns the first chapter' do
        headers = auth.merge('Idempotency-Key' => 'retry-1')
        post api_v1_fiction_chapters_path(@fiction), params: draft_body, headers:, as: :json
        first_id = response.parsed_body['id']
        post api_v1_fiction_chapters_path(@fiction),
             params: draft_body.merge(number: 99, title: 'Інший'), headers:, as: :json

        assert_response :created
        assert_equal first_id, response.parsed_body['id']
        assert_equal 1, Chapter.where(fiction: @fiction, user: @user).count
      end

      test 'two chapters with the same number are ambiguous' do
        post api_v1_fiction_chapters_path(fictions(:one)),
             params: draft_body.merge(number: chapters(:one).number), headers: auth, as: :json
        ScanlatorUser.create!(user: @user, scanlator: scanlators(:one))
        get by_number_api_v1_fiction_chapters_path(fictions(:one), chapters(:one).number), headers: auth

        assert_response :conflict
        assert_equal 'ambiguous', response.parsed_body.dig('error', 'code')
      end

      test 'writes past the limit are refused' do
        Rails.cache.increment("rate-limit:api/v1:write:#{@token.id}", Api::V1::BaseController::WRITES_PER_MINUTE,
                              expires_in: 1.minute)
        post api_v1_fiction_chapters_path(@fiction), params: draft_body, headers: auth, as: :json

        assert_response :too_many_requests
        assert_equal 'rate_limited', response.parsed_body.dig('error', 'code')
      end

      private

      def issue(user, scopes)
        token = ApiToken.issue!(user:, name: 'Claude', scopes:)
        [token, token.secret]
      end

      def auth
        { 'Authorization' => "Bearer #{@secret}" }
      end

      def draft_body
        { number: 12, title: 'Новий', content: 'Чернетка з абзацом.', scanlator_ids: [scanlators(:two).id] }
      end
    end
  end
end
