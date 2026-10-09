# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class ScopeProbesController < BaseController
      require_scope 'chapters:publish'

      def show
        render json: { ok: true }
      end
    end

    class BaseControllerTest < ActionDispatch::IntegrationTest
      setup do
        @token, @secret = issue
      end

      test 'a valid token returns the caller' do
        get api_v1_me_path, headers: auth
        body = response.parsed_body

        assert_response :success
        assert_equal users(:user_two).name, body.dig('user', 'name')
        assert_equal [{ 'id' => scanlators(:two).id, 'name' => 'Two' }], body['teams']
      end

      test 'the response describes the token and not the secret' do
        get api_v1_me_path, headers: auth
        body = response.parsed_body

        assert_equal @token.token_prefix, body.dig('token', 'prefix')
        assert_equal ['chapters:read', 'chapters:write'], body.dig('token', 'scopes')
        assert_not_includes response.body, @secret
      end

      test 'use is recorded at most once a minute' do
        travel_to Time.zone.parse('2026-10-09 12:00:00') do
          get api_v1_me_path, headers: auth
          used_at = @token.reload.last_used_at
          get api_v1_me_path, headers: auth

          assert_equal used_at, @token.reload.last_used_at

          travel 2.minutes
          get api_v1_me_path, headers: auth

          assert_operator @token.reload.last_used_at, :>, used_at
        end
      end

      test 'a missing or wrong token is unauthorized' do
        get api_v1_me_path

        assert_response :unauthorized
        assert_equal 'unauthorized', response.parsed_body.dig('error', 'code')

        get api_v1_me_path, headers: { 'Authorization' => "Bearer #{@secret}nope" }

        assert_response :unauthorized
      end

      test 'a revoked token is unauthorized' do
        @token.revoke!

        get api_v1_me_path, headers: auth

        assert_response :unauthorized
      end

      test 'an expired token is unauthorized' do
        travel_to @token.expires_at + 1.minute do
          get api_v1_me_path, headers: auth

          assert_response :unauthorized
        end
      end

      test 'a token without the scope is forbidden' do
        with_routing do |routes|
          routes.draw { get '/api/v1/probe', to: 'api/v1/scope_probes#show' }
          get '/api/v1/probe', headers: auth

          assert_response :forbidden
          assert_equal 'forbidden', response.parsed_body.dig('error', 'code')
        end
      end

      test 'reads past the limit are refused' do
        Rails.cache.increment(read_limit_key, Api::V1::BaseController::READS_PER_MINUTE, expires_in: 1.minute)

        get api_v1_me_path, headers: auth

        assert_response :too_many_requests
        assert_equal 'rate_limited', response.parsed_body.dig('error', 'code')
      end

      private

      def issue
        token = ApiToken.issue!(user: users(:user_two), name: 'Claude', scopes: ApiToken::DEFAULT_SCOPES)
        [token, token.secret]
      end

      def auth
        { 'Authorization' => "Bearer #{@secret}" }
      end

      def read_limit_key
        "rate-limit:api/v1:read:#{@token.id}"
      end
    end
  end
end
