# frozen_string_literal: true

require 'test_helper'

class HomeVideosSectionTest < ActionDispatch::IntegrationTest
  def setup
    Rails.cache.delete('home_videos/v1')
  end

  test 'popular videos section renders editorial shell' do
    Search::TagCounts.stub(:call, {}) { get root_url }

    assert_response :success
    assert_select 'h2#home-videos', text: /Популярні/
    assert_select 'section[aria-labelledby="home-videos"]', count: 1
  end

  test 'popular videos section links to youtube catalog' do
    Search::TagCounts.stub(:call, {}) { get root_url }

    assert_select "a[href='#{youtube_videos_path}']", text: /Більше/
  end

  test 'popular videos section uses iframe for featured and thumbnails for compact cards' do
    Search::TagCounts.stub(:call, {}) { get root_url }

    assert_select '[aria-label="Популярні Відео"] iframe[src*="youtube.com/embed"]', minimum: 1
    assert_select '[aria-label="Популярні Відео"] [data-controller="lazy-image"]', minimum: 1
  end

  test 'popular videos section uses featured and compact title clamps' do
    Search::TagCounts.stub(:call, {}) { get root_url }

    assert_select '[aria-label="Популярні Відео"] a.line-clamp-1', minimum: 1
    assert_select '[aria-label="Популярні Відео"] a.line-clamp-2', minimum: 1
  end

  test 'popular videos section uses asymmetrical desktop grid' do
    Search::TagCounts.stub(:call, {}) { get root_url }

    assert_select '.lg\\:grid-cols-\\[minmax\\(0\\,1\\.65fr\\)_minmax\\(0\\,1fr\\)\\]'
  end

  test 'popular videos mobile layout uses three column supporting grid without compact tags' do
    Search::TagCounts.stub(:call, {}) { get root_url }

    assert_select 'section[aria-labelledby="home-videos"] ul.grid.grid-cols-3.gap-2', count: 1
    assert_select 'section[aria-labelledby="home-videos"] .grid.grid-cols-3 .flex-nowrap', count: 0
  end

  test 'popular videos featured tags use responsive limits below desktop' do
    Search::TagCounts.stub(:call, {}) { get root_url }

    assert_select 'section[aria-labelledby="home-videos"] .flex.sm\\:hidden', minimum: 1
    assert_select 'section[aria-labelledby="home-videos"] .hidden.sm\\:flex.lg\\:hidden', minimum: 1
  end
end
