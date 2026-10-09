# frozen_string_literal: true

require 'test_helper'

class StudioFrameEscapeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'studio writings tab escapes frame for reading links' do
    sign_in users(:user_one)

    get studio_index_path(tab: 'writings')

    assert_select 'turbo-frame#fictions-list a[data-turbo-frame="_top"][href*="/readings/"]'
  end

  test 'studio writings tab escapes frame for fiction edit links' do
    sign_in users(:user_one)

    get studio_index_path(tab: 'writings')

    assert_select 'turbo-frame#fictions-list a[data-turbo-frame="_top"][href*="/edit"]'
  end

  test 'studio writings tab keeps new chapter on full reload' do
    sign_in users(:user_one)

    get studio_index_path(tab: 'writings')

    assert_select 'turbo-frame#fictions-list a[data-turbo="false"][href*="/chapters/new"]', minimum: 1
  end

  test 'studio bookshelves tab escapes frame for bookshelf show links' do
    sign_in users(:user_one)

    get studio_index_path(tab: 'bookshelves')

    assert_select 'turbo-frame#bookshelves-list a[data-turbo-frame="_top"][href*="/bookshelves/"]'
  end

  test 'studio teams tab opens the api docs as a full page' do
    sign_in users(:user_one)

    get studio_index_path(tab: 'teams')

    assert_select 'turbo-frame#tab-content a[data-turbo-frame="_top"][href="/developers"]',
                  text: I18n.t('api_tokens.docs')
  end

  test 'studio notifications empty state escapes frame for browse CTAs' do
    sign_in users(:user_two)

    get studio_index_path(tab: 'notifications')

    assert_select 'turbo-frame#tab-content a[data-turbo-frame="_top"][href*="/fictions"]'
  end

  test 'author readings list escapes frame for fiction browse links' do
    sign_in users(:user_one)

    get reading_url(fictions(:one))

    assert_select 'turbo-frame#chapters-list a[data-turbo-frame="_top"][href*="/fictions/"]', minimum: 1
  end
end
