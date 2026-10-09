# frozen_string_literal: true

require 'test_helper'

module Api
  module Chapters
    class UpdateTest < ActiveSupport::TestCase
      setup do
        @user = users(:user_two)
        @token = ApiToken.issue!(user: @user, name: 'Claude', scopes: %w[chapters:read chapters:write])
        @chapter = Create.call(
          user: @user, token: @token, fiction_id: fictions(:eighteen).id,
          params: { number: 20, title: 'Було', content: 'Текст чернетки.', scanlator_ids: [scanlators(:two).id] }
        ).chapter
      end

      teardown do
        Rails.cache.delete(Limits.counter_key(:create, @user, Date.current))
        Rails.cache.delete(Limits.counter_key(:published_edit_hour, @user, Time.current.strftime('%Y%m%d%H')))
        Rails.cache.delete(Limits.counter_key(:published_edit_day, @user, Date.current))
      end

      test 'a matching version updates the draft' do
        result = Update.call(user: @user, token: @token, chapter: @chapter, params: update_params(title: 'Стало'))

        assert_equal 'Стало', result.chapter.title
        assert_predicate result.chapter, :draft?
      end

      test 'a stale version changes nothing' do
        error = assert_raises(Error) do
          Update.call(
            user: @user, token: @token, chapter: @chapter,
            params: update_params(title: 'Стало', version: 'stale-version-value!!')
          )
        end

        assert_equal 'stale', error.code
        assert_equal 'Було', @chapter.reload.title
      end

      test 'a published chapter needs the publish scope' do
        publish_chapter!
        error = assert_raises(Error) do
          Update.call(
            user: @user, token: @token, chapter: @chapter,
            params: { title: 'Злам', version: Serialize.version(@chapter) }
          )
        end

        assert_equal 'publish_scope', error.code
        assert_equal :forbidden, error.status
      end

      private

      def update_params(**overrides)
        { title: 'Стало', version: Serialize.version(@chapter) }.merge(overrides)
      end

      def publish_chapter!
        @chapter.update!(content: 'а' * 500, status: :published)
      end
    end
  end
end
