# frozen_string_literal: true

require 'test_helper'

class FictionsIndexHotNoveltyTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'hot novelty section shows cover strip and featured card' do
    get fictions_path

    assert_select '#fictions-index-hot-novelty', text: 'Гарячі Новинки'
    assert_select '[aria-label="Гарячі Новинки — обкладинки"] button[data-fiction-picker-target="image"]', minimum: 1
    assert_select '#fiction_details a[data-turbo-frame="_top"][href*="/fictions/"]', minimum: 1
  end

  test 'an empty showcase and hot novelty say the filter removed them' do
    sign_in users(:user_one)
    empty = ->(**) { [] }

    Fictions::IndexVariablesManager.stub(:showcase, empty) do
      Fictions::IndexVariablesManager.stub(:popular_novelty, empty) do
        get fictions_path
      end
    end

    assert_select '[data-controller="custom-carousel"]', count: 0
    assert_select '[aria-label="Вітрина творів"] p.xl\:px-0', text: I18n.t('content_filters.empty')
    assert_select 'section[aria-labelledby="fictions-index-hot-novelty"] p', text: I18n.t('content_filters.empty')
  end

  test 'the fictions index says some results are hidden without summing the rails' do
    sign_in users(:user_one)

    get fictions_path

    assert_includes response.body, I18n.t('content_filters.some_hidden')
    assert_no_match(/Приховано \d+ за вашими налаштуваннями/, response.body)
  end

  test 'an empty popular ranobe row says the filter removed it' do
    sign_in users(:user_one)

    Fictions::IndexVariablesManager.stub(:most_reads, ->(**) { [] }) do
      get fictions_path
    end

    assert_select 'section[aria-labelledby="fictions-index-popular-ranobe"] p', text: I18n.t('content_filters.empty')
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
