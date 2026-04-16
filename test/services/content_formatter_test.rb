# frozen_string_literal: true

require 'test_helper'

class ContentFormatterTest < ActiveSupport::TestCase
  ChapterContent = Struct.new(:body, keyword_init: true)
  Chapter = Struct.new(:display_title_no_volume, :title, :content, keyword_init: true)

  test 'format_content emits valid empty elements for EPUB XHTML' do
    fragment = <<~HTML
      <p>Hi</p>
      <hr>
      <hr/>
      <br>
      <img src="https://example.com/a.png" alt="a">
      <img src="https://example.com/b.png" />
    HTML

    chapter = Chapter.new(
      display_title_no_volume: 'Test',
      title: nil,
      content: ChapterContent.new(body: fragment)
    )

    html = ContentFormatter.html(chapter)

    assert_includes html, '<hr />'
    assert_includes html, '<br />'
    assert_includes html, '<img src="https://example.com/a.png" alt="a" />'
    assert_includes html, '<img src="https://example.com/b.png" />'
    refute_includes html, '</hr>'
    refute_includes html, '</br>'
    refute_includes html, '</img>'
  end
end
