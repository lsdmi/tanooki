# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class ChapterProbesController < BaseController
      def show
        chapter = Api::Access.new(Current.user).chapter!(params[:id])
        render json: { id: chapter.id }
      end
    end

    class WriteProbesController < BaseController
      def create
        render json: { ok: true }
      end
    end

    class AccessControllerTest < ActionDispatch::IntegrationTest
      teardown { Api::Limits.allow_writes! }

      test 'another teams chapter is not found' do
        ChapterScanlator.create!(chapter: chapters(:three), scanlator: scanlators(:two))
        _token, secret = issue(users(:user_two))

        with_routing do |routes|
          routes.draw { get '/api/v1/chapters/:id', to: 'api/v1/chapter_probes#show' }
          get "/api/v1/chapters/#{chapters(:one).id}", headers: bearer(secret)

          assert_response :not_found
          assert_equal 'not_found', response.parsed_body.dig('error', 'code')
        end
      end

      test 'an admin token gets the same not found' do
        ChapterScanlator.create!(chapter: chapters(:three), scanlator: scanlators(:two))
        _token, secret = issue(users(:user_one))

        with_routing do |routes|
          routes.draw { get '/api/v1/chapters/:id', to: 'api/v1/chapter_probes#show' }
          get "/api/v1/chapters/#{chapters(:three).id}", headers: bearer(secret)

          assert_response :not_found
          assert_equal 'not_found', response.parsed_body.dig('error', 'code')
        end
      end

      test 'a member can read their own chapter' do
        ChapterScanlator.create!(chapter: chapters(:three), scanlator: scanlators(:two))
        _token, secret = issue(users(:user_two))

        with_routing do |routes|
          routes.draw { get '/api/v1/chapters/:id', to: 'api/v1/chapter_probes#show' }
          get "/api/v1/chapters/#{chapters(:three).id}", headers: bearer(secret)

          assert_response :success
          assert_equal chapters(:three).id, response.parsed_body['id']
        end
      end

      test 'the write switch refuses writes and still serves reads' do
        Api::Limits.stop_writes!
        _token, secret = issue(users(:user_two))
        get api_v1_me_path, headers: bearer(secret)

        assert_response :success

        with_routing do |routes|
          routes.draw { post '/api/v1/probe', to: 'api/v1/write_probes#create' }
          post '/api/v1/probe', headers: bearer(secret)

          assert_response :forbidden
          assert_equal 'writes_disabled', response.parsed_body.dig('error', 'code')
        end
      end

      test 'writes are served while the switch is on' do
        _token, secret = issue(users(:user_two))

        with_routing do |routes|
          routes.draw { post '/api/v1/probe', to: 'api/v1/write_probes#create' }
          post '/api/v1/probe', headers: bearer(secret)

          assert_response :success
          assert response.parsed_body['ok']
        end
      end

      private

      def issue(user)
        token = ApiToken.issue!(user:, name: 'Claude', scopes: ApiToken::DEFAULT_SCOPES)
        [token, token.secret]
      end

      def bearer(secret)
        { 'Authorization' => "Bearer #{secret}" }
      end
    end
  end
end
