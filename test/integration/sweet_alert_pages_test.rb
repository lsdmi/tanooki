# frozen_string_literal: true

require 'test_helper'

class SweetAlertPagesTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:user_one)
  end

  test 'studio writings keeps sweetalert stylesheet and buttons' do
    get studio_index_path(tab: 'writings')

    assert_select 'link[href*="sweetal2"][data-turbo-track="reload"]'
    assert_select 'button.sweet-alert-button[data-controller="sweet-alert"]', minimum: 1
  end

  test 'studio blogs keeps sweetalert stylesheet and buttons' do
    get studio_index_path(tab: 'blogs')

    assert_select 'link[href*="sweetal2"][data-turbo-track="reload"]'
    assert_select 'button.sweet-alert-button[data-controller="sweet-alert"]', minimum: 1
  end

  test 'studio teams keeps sweetalert stylesheet and buttons' do
    get studio_index_path(tab: 'teams')

    assert_select 'link[href*="sweetal2"][data-turbo-track="reload"]'
    assert_select 'button.sweet-alert-button[data-controller="sweet-alert"]', minimum: 1
  end

  test 'studio bookshelves keeps sweetalert stylesheet and buttons' do
    get studio_index_path(tab: 'bookshelves')

    assert_select 'link[href*="sweetal2"][data-turbo-track="reload"]'
    assert_select 'button.sweet-alert-button[data-controller="sweet-alert"]', minimum: 1
  end

  test 'readings chapter list keeps sweetalert stylesheet and buttons' do
    get reading_url(fictions(:one))

    assert_select 'link[href*="sweetal2"][data-turbo-track="reload"]'
    assert_select 'button.sweet-alert-button[data-controller="sweet-alert"]', minimum: 1
  end

  test 'scanlator show does not load unused sweetalert stylesheet' do
    get scanlator_path(scanlators(:one))

    assert_response :success
    assert_select 'link[href*="sweetal2"]', count: 0
  end
end
