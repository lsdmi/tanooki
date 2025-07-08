# frozen_string_literal: true

require 'test_helper'

class VideoInserterTest < ActiveSupport::TestCase
  def setup
    @video_inserter = VideoInserter.new
    @sample_html = '<p>First paragraph</p><p>Second paragraph</p><p>Third paragraph</p>'
    @video_url = 'https://www.youtube.com/embed/test123'
  end

  test 'insert_video returns original html when video_url is nil' do
    result = @video_inserter.insert_video(@sample_html, nil, after_paragraph: 1)
    assert_equal @sample_html, result
  end

  test 'insert_video returns original html when target paragraph does not exist' do
    result = @video_inserter.insert_video(@sample_html, @video_url, after_paragraph: 10)
    assert_equal @sample_html, result
  end

  test 'insert_video inserts video after first paragraph' do
    result = @video_inserter.insert_video(@sample_html, @video_url, after_paragraph: 0)

    doc = Nokogiri::HTML::DocumentFragment.parse(result)
    paragraphs = doc.css('p')
    iframes = doc.css('iframe')

    assert_equal 3, paragraphs.length
    assert_equal 1, iframes.length

    # The iframe should be after the first paragraph
    first_paragraph = paragraphs[0]
    iframe = iframes.first

    assert_equal first_paragraph.next_sibling, iframe
  end
end
