# frozen_string_literal: true

require 'test_helper'

module Books
  class EpubChapterHtmlTest < ActiveSupport::TestCase
    ChapterContent = Struct.new(:body, keyword_init: true)
    Chapter = Struct.new(:display_title_no_volume, :title, :content, keyword_init: true)

    SAMPLE_FRAGMENT = <<~HTML
      <p>Hi</p>
      <hr>
      <hr/>
      <br>
      <img src="https://example.com/a.png" alt="a">
      <img src="https://example.com/b.png" />
    HTML

    test 'normalizes hr and br to void elements in EPUB XHTML' do
      html = epub_html_for_body(SAMPLE_FRAGMENT)

      assert_includes html, '<hr />'
      assert_includes html, '<br />'
      assert_not_includes html, '</hr>'
    end

    test 'drops invalid closing tags for br' do
      html = epub_html_for_body(SAMPLE_FRAGMENT)

      assert_not_includes html, '</br>'
    end

    test 'normalizes img tags and drops invalid img close' do
      html = epub_html_for_body(SAMPLE_FRAGMENT)

      assert_includes html, '<img src="https://example.com/a.png" alt="a" />'
      assert_includes html, '<img src="https://example.com/b.png" />'
      assert_not_includes html, '</img>'
    end

    private

    def epub_html_for_body(body)
      chapter = Chapter.new(
        display_title_no_volume: 'Test',
        title: nil,
        content: ChapterContent.new(body: body)
      )
      EpubChapterHtml.html(chapter)
    end
  end
end
