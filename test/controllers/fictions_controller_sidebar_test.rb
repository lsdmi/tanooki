# frozen_string_literal: true

require 'test_helper'

class FictionsControllerSidebarTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:user_one)
    @fiction = fictions(:one)
  end

  test 'show defers sidebar stats in lazy turbo frame' do
    get fiction_url(@fiction)

    assert_select 'turbo-frame#fiction_sidebar_stats[loading="lazy"][src=?]', sidebar_stats_fiction_path(@fiction)
    assert_not_includes response.body, 'Славомір'
    assert_not_includes response.body, 'Відзнаки та нагороди'
  end

  test 'show defers similar fictions in lazy turbo frame' do
    get fiction_url(@fiction)

    assert_select 'turbo-frame#fiction_similar[loading="lazy"][src=?]', similar_fictions_fiction_path(@fiction)
    assert_not_includes response.body, 'Також може сподобатися'
  end

  test 'sidebar_stats frame renders monthly reads and ranks when present' do
    Rails.cache.write('hot_updates_counts', { @fiction.id => 5, fictions(:two).id => 10 }, expires_in: 1.hour)

    get sidebar_stats_fiction_url(@fiction)

    assert_response :success
    assert_select 'turbo-frame#fiction_sidebar_stats'
    assert_includes response.body, 'Славомір'
  ensure
    Rails.cache.delete('hot_updates_counts')
  end

  test 'similar_fictions frame renders recommendations' do
    get similar_fictions_fiction_url(@fiction)

    assert_response :success
    assert_select 'turbo-frame#fiction_similar'
    assert_includes response.body, 'Також може сподобатися'
  end

  test 'similar_fictions frame links to related titles' do
    get similar_fictions_fiction_url(@fiction)

    assert_includes response.body, fiction_path(fictions(:two))
  end

  test 'similar_fictions frame links escape turbo frame for full-page navigation' do
    get similar_fictions_fiction_url(@fiction)

    assert_select 'turbo-frame#fiction_similar a[data-turbo-frame="_top"][href*="/fictions/"]', minimum: 1
  end

  test 'similar_fictions frame is omitted on show when fiction has no scanlators' do
    fiction = fictions(:one)
    fiction.scanlators.destroy_all

    get fiction_url(fiction)

    assert_select 'turbo-frame#fiction_similar', count: 0
  end
end
