# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class WriteLogTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:user_two)
        @token, @secret = issue
        @fiction = fictions(:eighteen)
        FictionScanlator.create!(fiction: @fiction, scanlator: scanlators(:two))
      end

      teardown do
        Rails.cache.delete(Api::Limits.counter_key(:create, @user, Date.current))
      end

      test 'a write is logged without the secret or the body' do
        lines = []
        record = ->(*args, **_kwargs, &_block) { lines << args.join }
        Rails.logger.stub(:info, record) do
          post api_v1_fiction_chapters_path(@fiction), params: draft_body, headers: auth, as: :json
        end
        line = lines.grep(/\A\[API\]/).join("\n")
        created_id = response.parsed_body['id']

        assert_match(write_line(created_id), line)
        assert_not line.match?(/#{Regexp.escape(@secret)}|Чернетка/)

        lines.clear
        Rails.logger.stub(:info, record) do
          get api_v1_fiction_chapters_path(@fiction), headers: auth
        end

        assert_empty lines.grep(/\A\[API\]/)
      end

      private

      def issue
        token = ApiToken.issue!(user: @user, name: 'Claude', scopes: %w[chapters:read chapters:write])
        [token, token.secret]
      end

      def auth
        { 'Authorization' => "Bearer #{@secret}" }
      end

      def draft_body
        { number: 12, title: 'Новий', content: 'Чернетка з абзацом.', scanlator_ids: [scanlators(:two).id] }
      end

      def write_line(created_id)
        %r{token=#{@token.id} action=api/v1/fiction_chapters#create chapter=#{created_id} status=201}
      end
    end
  end
end
