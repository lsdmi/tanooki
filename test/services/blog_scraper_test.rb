# frozen_string_literal: true

require 'test_helper'

class BlogScraperTest < ActiveSupport::TestCase
  test 'fetch_content returns early when no items' do
    mock_rss_fetcher = Minitest::Mock.new
    mock_rss_fetcher.expect(:fetch_items, [])

    scraper = BlogScraper.new(rss_fetcher: mock_rss_fetcher)
    result = scraper.fetch_content

    assert_nil result
    mock_rss_fetcher.verify
  end

  test 'fetch_content processes items' do
    mock_rss_fetcher = Minitest::Mock.new
    mock_content_processor = Minitest::Mock.new
    mock_publication_creator = Minitest::Mock.new

    mock_item = Minitest::Mock.new
    mock_processed_content = Minitest::Mock.new

    mock_rss_fetcher.expect(:fetch_items, [mock_item])
    mock_content_processor.expect(:process, mock_processed_content, [mock_item])
    mock_publication_creator.expect(:create, true, [mock_processed_content])

    scraper = BlogScraper.new(
      rss_fetcher: mock_rss_fetcher,
      content_processor: mock_content_processor,
      publication_creator: mock_publication_creator
    )
    result = scraper.fetch_content

    assert_equal [mock_item], result
    mock_rss_fetcher.verify
    mock_content_processor.verify
    mock_publication_creator.verify
  end
end
