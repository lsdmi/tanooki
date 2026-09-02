# frozen_string_literal: true

require 'test_helper'

class FictionsIndexNewReleasesTest < ActionDispatch::IntegrationTest
  test 'new releases section lists update cards linking to chapters' do
    get fictions_path

    assert_select '#fictions-index-new-releases', text: 'Нові Релізи'
    assert_select '[aria-label="Нові Релізи"] article', minimum: 1
    assert_select '[aria-label="Нові Релізи"] a[href*="chapters"]', minimum: 1
  end

  test 'new releases section uses two columns on desktop and a slider below sm' do
    get fictions_path

    assert_select 'ul[aria-label="Нові Релізи"].sm\\:grid-cols-2', 1
    assert_select '[aria-label="Нові Релізи"].snap-x .snap-start.flex-col', minimum: 1
  end

  test 'new releases section is capped at six cards' do
    get fictions_path

    assert_select 'ul[aria-label="Нові Релізи"] > li', maximum: Fictions::IndexVariablesManager::LATEST_UPDATES_INDEX_CARDS
  end
end
