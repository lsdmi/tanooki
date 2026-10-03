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
    assert_not_includes response.body, 'Відзнаки та нагороди'
  end

  test 'show defers similar fictions in lazy turbo frame' do
    get fiction_url(@fiction)

    assert_select 'turbo-frame#fiction_similar[loading="lazy"][src=?]', similar_fictions_fiction_path(@fiction)
    assert_select '#fiction-similar-title', 0
  end

  test 'sidebar_stats frame renders honors for ranked genres with badge artwork' do
    Genre.create!(name: 'Комедія', slug: 'comedy')
    Rails.cache.write("fiction-#{@fiction.slug}-ranks", { 'Комедія' => 1, 'Жанр Альфа' => 2 })

    get sidebar_stats_fiction_url(@fiction)

    assert_select 'turbo-frame#fiction_sidebar_stats #fiction-honors-title', text: 'Відзнаки та нагороди'
    assert_select '#fiction_sidebar_stats a[href="/fictions/genres/comedy"]', text: /#1/
  ensure
    Rails.cache.delete("fiction-#{@fiction.slug}-ranks")
  end

  test 'sidebar_stats frame stays empty without ranks' do
    Rails.cache.write("fiction-#{@fiction.slug}-ranks", {})

    get sidebar_stats_fiction_url(@fiction)

    assert_select 'turbo-frame#fiction_sidebar_stats section', 0
  ensure
    Rails.cache.delete("fiction-#{@fiction.slug}-ranks")
  end

  test 'similar_fictions frame renders recommendations' do
    get similar_fictions_fiction_url(@fiction)

    assert_response :success
    assert_select 'turbo-frame#fiction_similar #fiction-similar-title', text: 'Схожі твори'
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
