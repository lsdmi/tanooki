# frozen_string_literal: true

require 'test_helper'

module Chapters
  class ParagraphsTest < ActiveSupport::TestCase
    setup do
      @note = '<p style="text-align: center">До <span class="note-reference" data-note="примітка" ' \
              'data-note-id="note-1">слова</span>.</p>'
      @html = "<p>Перший абзац.</p>#{@note}"
    end

    test 'an edit keeps the exact html of untouched blocks' do
      result = Paragraphs.apply(@html, [{ n: 1, old: 'Перший абзац.', new: 'Змінений' }])

      assert_includes result, @note
      assert_includes result, 'Змінений'
      assert_not_includes result, 'Перший абзац.'
    end

    test 'a wrong old is rejected with the current text' do
      error = assert_raises(Api::Error) { Paragraphs.apply(@html, [{ n: 1, old: 'не те', new: 'Змінений' }]) }

      assert_equal 'paragraph_mismatch', error.code
      assert_equal 'Перший абзац.', error.details[:current]
    end

    test 'an empty replacement deletes the block and blank lines split one' do
      deleted = Paragraphs.apply(@html, [{ n: 1, old: 'Перший абзац.', new: '' }])
      split = Paragraphs.apply(@html, [{ n: 1, old: 'Перший абзац.', new: "Альфа\n\nБета" }])

      assert_equal @note, deleted
      assert_includes split, 'Альфа'
      assert_includes split, @note
    end
  end
end
