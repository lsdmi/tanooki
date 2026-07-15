# frozen_string_literal: true

require 'test_helper'

class HomeTalesSectionTest < ActionDispatch::IntegrationTest
  def setup
    Rails.cache.delete('top_tales')
  end

  test 'news and blogs section renders full-width editorial shell' do
    Search::TagCounts.stub(:call, {}) { get root_url }

    assert_response :success
    assert_select 'h2#home-tales', text: /Новини та/
    assert_select 'section[aria-labelledby="home-tales"].w-full', count: 1
  end

  test 'news and blogs section uses writer background and catalog link' do
    Search::TagCounts.stub(:call, {}) { get root_url }

    assert_select '.home-tales.w-full.bg-blend-multiply[style*="writer"]', count: 1
    assert_select "a[href='#{tales_path}']", text: /Більше/
  end

  test 'news and blogs cards expose dynamic text clamp targets' do
    Search::TagCounts.stub(:call, {}) { get root_url }

    assert_select '[data-controller="tale-card-text"]', minimum: 1
    assert_select '[data-tale-card-text-target="title"].line-clamp-2', minimum: 1
    assert_select '[data-tale-card-text-target="description"].line-clamp-2', minimum: 1
  end

  test 'news and blogs section uses asymmetrical desktop grid and compact aspect ratio' do
    Search::TagCounts.stub(:call, {}) { get root_url }

    assert_select '[aria-label="Новини та Блоги"] .aspect-video', minimum: 1
    assert_select '.lg\\:grid-cols-\\[minmax\\(0\\,1fr\\)_minmax\\(0\\,2\\.15fr\\)_minmax\\(0\\,1fr\\)\\]'
  end
end
