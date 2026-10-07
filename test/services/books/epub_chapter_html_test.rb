# frozen_string_literal: true

require 'test_helper'

module Books
  class EpubChapterHtmlTest < ActiveSupport::TestCase
    ChapterContent = Struct.new(:body, keyword_init: true)
    Chapter = Struct.new(:display_title_no_volume, :title, :content, keyword_init: true)
    HtmlBody = Struct.new(:html) do
      def to_html
        html
      end
    end

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

    test 'uses raw html body without action view render' do
      chapter = chapters(:one)
      EpubChapterBodies.stub(:raw_html, '<p>Hi</p>') do
        html = EpubChapterHtml.html(chapter)

        assert_includes html, '<p>Hi</p>'
      end
    end

    test 'drops reader-owned inline styles from the chapter body' do
      body = reader_style_html.split('<body', 2).last

      assert_includes body,
                      '<p>Stay</p><p style="font-weight: 700">Hi</p><p>Only</p>' \
                      "<p style='text-align: center'>Size</p><p style=\"border-color: red\">Edge</p>"
    end

    test 'keeps the book stylesheet line-height and link color' do
      html = reader_style_html

      assert_includes html, 'line-height: 1.5'
      assert_includes html, 'color: #0000FF'
    end

    test 'skips regexp normalization for very large chapter bodies' do
      large_body = "#{'x' * (Books::EpubChapterHtml::LARGE_CONTENT_BYTES + 1)}<hr>"
      html = epub_html_for_body(large_body)

      assert_includes html, large_body
      assert_not_includes html, '<hr />'
    end

    private

    def reader_style_html
      epub_html_for_body(
        '<p style="color: blue;">Stay</p>' \
        '<p style="font-weight: 700; font-family: Courier; font-size: 24px; line-height: 2; color: red">Hi</p>' \
        '<p style="line-height:1.5">Only</p>' \
        '<p style=\'text-align: center; font-size: 16px; line-height: 200%\'>Size</p>' \
        '<p style="border-color: red; font: 16px Courier">Edge</p>'
      )
    end

    def epub_html_for_body(body_html)
      chapter = Chapter.new(
        display_title_no_volume: 'Test',
        title: nil,
        content: ChapterContent.new(body: HtmlBody.new(body_html))
      )
      EpubChapterBodies.stub(:raw_html, body_html) do
        EpubChapterHtml.html(chapter)
      end
    end
  end
end
