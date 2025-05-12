# frozen_string_literal: true

require 'test_helper'

class BlogScraperTest < ActiveSupport::TestCase
  test 'fetch_content returns nil when no RSS items' do
    BlogScraper.stub :fetch_rss_items, [] do
      assert_nil BlogScraper.fetch_content
    end
  end

  test 'filter_by_time returns only recent items' do
    now = Time.current
    old_item = OpenStruct.new(pubDate: now - 3.hours)
    new_item = OpenStruct.new(pubDate: now - 1.hour)
    result = BlogScraper.send(:filter_by_time, [old_item, new_item], 2)
    assert_equal [new_item], result
  end

  test 'filter_by_indices returns items at given indices' do
    items = %w[a b c d]
    result = BlogScraper.send(:filter_by_indices, items, [1, 3])
    assert_equal %w[b d], result
  end

  test 'extract_title_and_description splits h1 and body' do
    html = '<h1>Title</h1><p>Desc</p>'
    title, desc = BlogScraper.send(:extract_title_and_description, html)
    assert_equal 'Title', title
    assert_match 'Desc', desc
  end

  test 'fetch_rss_items logs error and returns empty array on exception' do
    Faraday.stub :get, ->(*) { raise StandardError, 'fail' } do
      Rails.logger.stub :error, nil do
        assert_equal [], BlogScraper.send(:fetch_rss_items)
      end
    end
  end
end
