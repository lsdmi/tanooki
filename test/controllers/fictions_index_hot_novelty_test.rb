# frozen_string_literal: true

require 'test_helper'

class FictionsIndexHotNoveltyTest < ActionDispatch::IntegrationTest
  test 'hot novelty section shows cover strip and featured card' do
    get fictions_path

    assert_select '#fictions-index-hot-novelty', text: 'Гарячі Новинки'
    assert_select '[aria-label="Гарячі Новинки — обкладинки"] button[data-fiction-picker-target="image"]', minimum: 1
    assert_select '#fiction_details a[data-turbo-frame="_top"][href*="/fictions/"]', minimum: 1
  end

  test 'hot novelty section is capped at the configured cover count' do
    get fictions_path

    assert_select '[aria-label="Гарячі Новинки — обкладинки"] button',
                  maximum: Fictions::IndexVariablesManager::POPULAR_NOVELTY_INDEX_CARDS
  end

  test 'cover strip does not preload genres or ratings it never renders' do
    get fictions_path

    assert_response :success

    loaded = Fictions::IndexVariablesManager.popular_novelty.to_a.flat_map do |fiction|
      [fiction.association(:genres).loaded?, fiction.association(:fiction_ratings).loaded?]
    end

    assert_equal [], loaded.uniq - [false]
  end

  test 'hot novelty header links to the alphabetical catalog' do
    get fictions_path

    assert_select "a[href='#{alphabetical_fictions_path}']", text: /Сховище/
  end

  test 'picker variant keeps the featured card partial on turbo stream replace' do
    get details_fiction_url(fictions(:two), variant: 'hot_novelty', format: :turbo_stream)

    assert_response :success
    assert_select 'turbo-stream[action="replace"][target="fiction_details"]', count: 1
    assert_match 'Розділи', response.body
  end

  test 'details without a variant keeps the legacy details partial' do
    get details_fiction_url(fictions(:two), format: :turbo_stream)

    assert_response :success
    assert_match 'Читати', response.body
  end
end
