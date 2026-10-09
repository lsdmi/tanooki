# frozen_string_literal: true

require 'test_helper'

module Api
  module Chapters
    class CreateTest < ActiveSupport::TestCase
      setup do
        @user = users(:user_two)
        @fiction = fictions(:eighteen)
        @token = ApiToken.issue!(user: @user, name: 'Claude', scopes: %w[chapters:read chapters:write])
      end

      teardown do
        Rails.cache.delete(Limits.counter_key(:create, @user, Date.current))
      end

      test 'a draft is saved for the callers own team' do
        result = create_chapter

        assert_predicate result.chapter, :draft?
        assert_equal [@user.scanlators.ids], [result.chapter.scanlators.ids]
        assert_includes result.chapter.content.to_s, 'Чернетка'
      end

      test 'an api chapter records who created it' do
        chapter = create_chapter.chapter

        assert_equal 'api', chapter.created_via
        assert_equal @token, chapter.api_token
      end

      test 'an admin cannot attach another team' do
        admin = users(:user_one)
        token = ApiToken.issue!(user: admin, name: 'Admin', scopes: ApiToken::SCOPES)
        before = Chapter.count

        error = assert_raises(Error) do
          Create.call(
            user: admin, token:, fiction_id: @fiction.id,
            params: draft_params(scanlator_ids: [scanlators(:two).id])
          )
        end

        assert_equal 'scanlator_ids', error.code
        assert_equal before, Chapter.count
      end

      test 'publishing without the scope is forbidden' do
        before = Chapter.count
        error = assert_raises(Error) { create_chapter(status: 'published', content: 'а' * 500) }

        assert_equal 'publish_scope', error.code
        assert_equal before, Chapter.count
      end

      test 'the same number on the callers team conflicts' do
        create_chapter(number: 4)
        error = assert_raises(Error) { create_chapter(number: 4) }

        assert_equal 'conflict', error.code
        assert_equal :conflict, error.status
      end

      test 'the same number on another team does not conflict' do
        result = Create.call(
          user: @user, token: @token, fiction_id: fictions(:one).id,
          params: draft_params(number: chapters(:one).number, scanlator_ids: [scanlators(:two).id])
        )

        assert_predicate result.chapter, :persisted?
        assert_equal chapters(:one).number, result.chapter.number
      end

      test 'a short published chapter is rejected' do
        publish = ApiToken.issue!(user: @user, name: 'Live', scopes: %w[chapters:read chapters:publish])
        error = assert_raises(Error) { create_chapter(token: publish, status: 'published', content: 'коротко') }

        assert_equal 'invalid', error.code
        assert_match(/коротк/, error.details[:content].join)
      end

      test 'a past published_at is rejected' do
        publish = ApiToken.issue!(user: @user, name: 'Live', scopes: %w[chapters:read chapters:publish])
        error = assert_raises(Error) do
          create_chapter(token: publish, status: 'published', content: 'а' * 500, published_at: 2.days.ago.iso8601)
        end

        assert_equal 'invalid', error.code
        assert_match(/минул/, error.details[:published_at].join)
      end

      test 'removed markup is listed on the write' do
        result = create_chapter(content: '<p>Привіт</p><script>x</script>', content_format: 'html')

        assert_includes result.changes.join, 'script'
      end

      private

      def create_chapter(**params)
        token = params.delete(:token) || @token
        Create.call(user: @user, token:, fiction_id: @fiction.id, params: draft_params(**params))
      end

      def draft_params(**overrides)
        {
          number: 12, title: 'Новий', content: 'Чернетка з абзацом.', content_format: 'markdown',
          scanlator_ids: [scanlators(:two).id]
        }.merge(overrides)
      end
    end
  end
end
