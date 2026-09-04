# frozen_string_literal: true

require 'test_helper'

class FictionsIndexPopularRanobeTest < ActionDispatch::IntegrationTest
  test 'renders the most-read list as a ranked horizontal strip' do
    expected = Fictions::IndexVariablesManager.most_reads.to_a

    get fictions_path

    assert_select '#fictions-index-popular-ranobe', text: /Популярне\s+Ранобе/
    assert_select '[aria-labelledby="fictions-index-popular-ranobe"] [aria-label="Популярне ранобе"] article',
                  count: expected.size
    assert_select '[aria-labelledby="fictions-index-popular-ranobe"] article > a > span', text: '1', count: 1
  end

  test 'ranked strip is capped at the configured most-read count' do
    get fictions_path

    assert_select '[aria-labelledby="fictions-index-popular-ranobe"] [aria-label="Популярне ранобе"] article',
                  maximum: Fictions::IndexVariablesManager::MOST_READS_INDEX_CARDS
  end

  test 'legacy top ranobe column still shows the first six' do
    get fictions_path

    assert_select 'h2', text: 'Топ Ранобе'
    assert_select 'img.h-48', maximum: Fictions::IndexVariablesManager::MOST_READS_SIDEBAR_CARDS
  end

  test 'ranked strip renders genres as pills' do
    get fictions_path

    assert_select '[aria-labelledby="fictions-index-popular-ranobe"] article .pb-2 a.border', minimum: 1
  end

  test 'header links to the alphabetical catalog' do
    get fictions_path

    assert_response :success
    assert_select "[aria-labelledby='fictions-index-popular-ranobe'] a[href='#{alphabetical_fictions_path}']",
                  text: /Більше/
  end
end
