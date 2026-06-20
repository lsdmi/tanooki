# frozen_string_literal: true

require 'test_helper'

class TurboBatch4StudioDashboardTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'studio writings tab escapes turbo frame for reading and edit actions' do
    sign_in users(:user_one)

    get studio_index_path(tab: 'writings')

    assert_response :success
    assert_select 'turbo-frame#fictions-list a[data-turbo-frame="_top"][href*="/readings/"]'
    assert_select 'turbo-frame#fictions-list a[data-turbo-frame="_top"][href*="/fictions/"][href*="/edit"]'
  end

  test 'studio writings tab keeps new chapter on full reload' do
    sign_in users(:user_one)

    get studio_index_path(tab: 'writings')

    assert_response :success
    assert_select 'turbo-frame#fictions-list a[data-turbo="false"][href*="/chapters/new"]', minimum: 1
  end

  test 'studio bookshelves tab escapes turbo frame for view and keeps edit on full reload' do
    sign_in users(:user_one)

    get studio_index_path(tab: 'bookshelves')

    assert_response :success
    assert_select 'turbo-frame#bookshelves-list a[data-turbo-frame="_top"][href*="/bookshelves/"]'
    assert_select 'turbo-frame#bookshelves-list a[data-turbo="false"][href*="/edit"]', minimum: 1
  end

  test 'studio notifications empty state escapes turbo frame for browse CTAs' do
    sign_in users(:user_two)

    get studio_index_path(tab: 'notifications')

    assert_response :success
    assert_select 'turbo-frame#tab-content a[data-turbo-frame="_top"][href*="/fictions"]'
    assert_select 'turbo-frame#tab-content a[data-turbo-frame="_top"][href*="/calendar"]'
  end

  test 'author readings chapter list escapes turbo frame for fiction browse links' do
    sign_in users(:user_one)
    fiction = fictions(:one)

    get reading_url(fiction)

    assert_response :success
    assert_select 'turbo-frame#chapters-list a[data-turbo-frame="_top"][href*="/fictions/"]', minimum: 1
    assert_select 'turbo-frame#chapters-list a[data-turbo-frame="_top"][href*="/edit"]'
  end

  test 'author readings chapter list keeps new chapter on full reload' do
    sign_in users(:user_one)
    fiction = fictions(:one)

    get reading_url(fiction)

    assert_response :success
    assert_select 'turbo-frame#chapters-list a[data-turbo="false"][href*="/chapters/new"]', minimum: 1
  end
end
