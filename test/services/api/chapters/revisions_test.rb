# frozen_string_literal: true

require 'test_helper'

module Api
  module Chapters
    class RevisionsTest < ActiveSupport::TestCase
      setup do
        @user = users(:user_two)
        @token = ApiToken.issue!(user: @user, name: 'Claude', scopes: %w[chapters:read chapters:write chapters:publish])
        @chapter = Create.call(
          user: @user, token: @token, fiction_id: fictions(:eighteen).id,
          params: {
            number: 31, title: 'Було', content: "Перший абзац.\n\nДругий абзац.",
            scanlator_ids: [scanlators(:two).id]
          }
        ).chapter
      end

      teardown do
        Rails.cache.delete(Limits.counter_key(:create, @user, Date.current))
      end

      test 'a title change stores the previous title' do
        Update.call(
          user: @user, token: @token, chapter: @chapter,
          params: { title: 'Стало', version: Serialize.version(@chapter) }
        )

        assert_equal 'Було', @chapter.revisions.last.title
        assert_equal 'Стало', @chapter.reload.title
      end

      test 'revert restores the body and keeps its own revision' do
        EditParagraphs.call(user: @user, token: @token, chapter: @chapter, params: edit_params('Змінений'))
        snapshot = @chapter.revisions.last

        Revert.call(user: @user, token: @token, chapter: @chapter.reload, revision: snapshot)

        assert_includes @chapter.reload.content.to_s, 'Перший абзац'
        assert_equal 2, @chapter.revisions.count
      end

      test 'the diff marks the changed paragraph' do
        EditParagraphs.call(user: @user, token: @token, chapter: @chapter, params: edit_params('Змінений'))
        rows = Diff.call(@chapter.reload, @chapter.revisions.last)

        changed = rows.find { |row| row[:change] == 'changed' }

        assert_equal 'Перший абзац.', changed[:old]
        assert_equal 'Змінений', changed[:new]
      end

      private

      def edit_params(text)
        old = ::Chapters::Paragraphs.list(@chapter.content.to_s).first[:markdown]
        { version: Serialize.version(@chapter), edits: [{ n: 1, old:, new: text }] }
      end
    end
  end
end
