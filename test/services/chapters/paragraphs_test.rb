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

    test 'an h1 is read and written as a markdown heading' do
      html = '<h1><strong>Пролог</strong></h1>'
      listed = Paragraphs.list(html)
      rewritten = Paragraphs.apply(html, [{ n: 1, old: listed.first[:markdown], new: '# Пролог 2' }])

      assert_equal '# **Пролог**', listed.first[:markdown]
      assert_equal '<h1>Пролог 2</h1>', rewritten
    end

    test 'an empty replacement deletes the block and blank lines split one' do
      deleted = Paragraphs.apply(@html, [{ n: 1, old: 'Перший абзац.', new: '' }])
      split = Paragraphs.apply(@html, [{ n: 1, old: 'Перший абзац.', new: "Альфа\n\nБета" }])

      assert_equal @note, deleted
      assert_includes split, 'Альфа'
      assert_includes split, @note
    end

    test 'a no-op keeps tinymce spans and dir byte-for-byte' do
      html = '<p dir="ltr"><span style="font-family: tahoma, arial, helvetica, sans-serif; font-size: 12pt;">' \
             'Каролін згадала <span style="font-weight: bold;">Гуакамоле</span>.</span></p>'
      listed = Paragraphs.list(html)
      result = Paragraphs.apply(html, [{ n: 1, old: listed.first[:markdown], new: listed.first[:markdown] }])

      assert_equal html, result
      assert_includes listed.first[:markdown], '**Гуакамоле**'
    end

    test 'a plain text edit rewrites inside tinymce html without dropping styles' do
      html = '<p dir="ltr"><span style="font-family: tahoma; font-size: 12pt;">' \
             'Каролін згадала <span style="font-weight: bold;">Гуакамоле</span>.</span></p>'
      listed = Paragraphs.list(html)
      result = Paragraphs.apply(
        html,
        [{ n: 1, old: listed.first[:markdown], new: 'Каролін пригадала **Гуакамоле**.' }]
      )

      assert_equal(
        [true, true, true],
        [result.include?('dir="ltr"'), result.include?('font-weight: bold'), result.include?('пригадала')]
      )
      assert_includes result, 'font-family: tahoma'
      assert_not_includes result, 'згадала'
    end

    test 'a plain text edit keeps note spans and paragraph styles' do
      listed = Paragraphs.list(@note)
      result = Paragraphs.apply(@note, [{ n: 1, old: listed.first[:markdown], new: 'Після слова.' }])

      assert_equal(
        [true, true, true],
        [result.include?('text-align: center'), result.include?('note-reference'), result.include?('Після')]
      )
      assert_includes result, 'data-note="примітка"'
      assert_not_includes result, 'До '
    end

    test 'keeping bold markers updates text inside strong without re-render' do
      html = '<h1><strong>Пролог</strong></h1>'
      result = Paragraphs.apply(html, [{ n: 1, old: '# **Пролог**', new: '# **Епілог**' }])

      assert_equal '<h1><strong>Епілог</strong></h1>', result
    end
  end
end
