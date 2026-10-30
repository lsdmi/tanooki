# frozen_string_literal: true

require 'test_helper'

class FictionListsContentFilterTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @everyone = fictions(:one)
    @sixteen = fictions(:two)
    @eighteen = fictions(:eighteen)
  end

  test 'a rating cap hides 18+ even when the session checkbox is on' do
    sign_in users(:user_one)

    get alphabetical_fictions_url, params: { filters_applied: '1', include_eighteen: '1' }

    assert_select 'a[href=?]', fiction_path(@eighteen), count: 0
    assert_select 'a[href=?]', fiction_path(@sixteen)
    assert_select 'input[name=include_eighteen][disabled]'
  end

  test 'the locked checkbox still submits the remembered 18+ preference' do
    sign_in users(:user_one)
    get alphabetical_fictions_url, params: { filters_applied: '1', include_eighteen: '1' }

    assert_select 'input[type=hidden][name=include_eighteen][value=1]'

    get alphabetical_fictions_url, params: { filters_applied: '1', include_eighteen: '1', only_new: '1' }

    assert session[:catalog_include_eighteen]
  end

  test 'saving the guest cookie disables the catalog checkbox in the same response' do
    patch content_filter_path, params: { max_content_rating: '16' }, as: :turbo_stream

    assert_response :success
    assert_includes response.body, 'catalog-include-eighteen-guest-content-filter'
    assert_includes response.body, 'disabled'
  end

  test 'a guest who hides 18+ cannot turn them back on from the catalog checkbox' do
    patch content_filter_path, params: { max_content_rating: '16' }

    get alphabetical_fictions_url, params: { include_eighteen: '1' }

    assert_select 'a[href=?]', fiction_path(@eighteen), count: 0
    assert_select 'input[name=include_eighteen][disabled]'
    assert_select '#catalog-include-eighteen-guest-content-filter a[data-turbo-frame=?]', '_top', text: 'Змінити'
  end

  test 'picking a hidden genre keeps those works out and says the genre is hidden' do
    sign_in users(:user_two)
    FictionGenre.create!(fiction: @everyone, genre: genres(:bl))

    get alphabetical_fictions_url, params: { genre: genres(:bl).id }

    assert_select '#fiction-list-page [data-fiction-picker-id-param=?]', @everyone.id.to_s, count: 0
    assert_includes response.body, I18n.t('content_filters.genre_hidden')
    assert_select 'turbo-frame#fiction-list-page a[href=?][data-turbo-frame=?]',
                  studio_index_path(tab: 'profile'), '_top',
                  text: 'Змінити'
  end

  test 'an active filter says the catalog list is filtered' do
    sign_in users(:user_one)

    get alphabetical_fictions_url

    assert_includes response.body, I18n.t('content_filters.some_hidden')
  end

  test 'a hidden genre stays out of the catalog' do
    sign_in users(:user_two)
    FictionGenre.create!(fiction: @everyone, genre: genres(:bl))

    get alphabetical_fictions_url

    assert_select '#fiction-list-page [data-fiction-picker-id-param=?]', @everyone.id.to_s, count: 0
  end
end
