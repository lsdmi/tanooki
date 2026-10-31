# frozen_string_literal: true

require 'test_helper'

class StudioFrameEscapeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'studio tab list syncs the active tab via stimulus' do
    sign_in users(:user_one)

    get studio_index_path(tab: 'writings')

    assert_select '#default-tab[data-controller~=studio-tabs]'
  end

  test 'studio tab links request streams without targeting tab-content as a frame' do
    sign_in users(:user_one)

    get studio_index_path(tab: 'writings')

    assert_select '#writings-tab[data-turbo-stream]'
    assert_select '#writings-tab[data-turbo-frame]', count: 0
    assert_select '#pokemons-tab[data-turbo-stream]'
  end

  test 'pokemon studio tab link also omits turbo-frame targeting' do
    sign_in users(:user_one)

    get studio_index_path(tab: 'writings')

    assert_select '#pokemons-tab[data-turbo-frame]', count: 0
  end

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
    assert_select 'turbo-frame#tab-content', text: /0 з 60/
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
