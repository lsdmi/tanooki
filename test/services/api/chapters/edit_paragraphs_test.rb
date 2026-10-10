# frozen_string_literal: true

require 'test_helper'

module Api
  module Chapters
    class EditParagraphsTest < ActiveSupport::TestCase
      setup do
        @user = users(:user_two)
        @token = ApiToken.issue!(user: @user, name: 'Claude', scopes: %w[chapters:read chapters:write])
        @chapter = Create.call(
          user: @user, token: @token, fiction_id: fictions(:eighteen).id,
          params: {
            number: 30, title: 'Абзаци', content: "Перший абзац.\n\nДругий абзац.",
            scanlator_ids: [scanlators(:two).id]
          }
        ).chapter
      end

      teardown do
        Rails.cache.delete(Limits.counter_key(:create, @user, Date.current))
        Rails.cache.delete(Limits.counter_key(:published_edit_hour, @user, Limits::PublishedEdits.hour_period))
        Rails.cache.delete(Limits.counter_key(:published_edit_span, @user, Limits::PublishedEdits.span_period))
      end

      test 'a paragraph edit keeps the other block and stores a revision' do
        result = edit(number: 1, replacement: 'Змінений')
        previous = ::Chapters::Paragraphs.list(result.chapter.revisions.last.body).first[:markdown]

        assert_includes result.chapter.content.to_s, 'Другий абзац'
        assert_includes result.chapter.content.to_s, 'Змінений'
        assert_equal 'Перший абзац.', previous
      end

      test 'a stale version changes nothing' do
        error = assert_raises(Error) { edit(number: 1, replacement: 'Змінений', version: 'stale-version-value!!') }

        assert_equal 'stale', error.code
        assert_empty @chapter.revisions
      end

      test 'a published chapter needs the publish scope' do
        @chapter.update!(content: "#{'а' * 250}\n\n#{'б' * 250}", status: :published)
        error = assert_raises(Error) { edit(number: 1, replacement: 'Змінений') }

        assert_equal 'publish_scope', error.code
        assert_equal :forbidden, error.status
      end

      private

      def edit(number:, replacement:, version: Serialize.version(@chapter))
        blocks = ::Chapters::Paragraphs.list(@chapter.content.to_s)
        old = blocks.find { |block| block[:n] == number }[:markdown]
        EditParagraphs.call(
          user: @user, token: @token, chapter: @chapter,
          params: { version:, edits: [{ n: number, old:, new: replacement }] }
        )
      end
    end
  end
end
