# frozen_string_literal: true

require 'test_helper'

class LayoutFragmentCacheTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'guest navbar shows login link' do
    get fictions_path

    assert_response :success
    assert_select 'nav a[href=?]', new_user_session_path, text: 'Увійти'
  end

  test 'guest navbar omits auth dropdown' do
    get fictions_path

    assert_select 'nav #user-dropdown', count: 0
  end

  test 'signed in navbar shows auth dropdown on browse page' do
    sign_in users(:user_one)

    get fictions_path

    assert_response :success
    assert_select 'nav #user-dropdown #accountDropdown2'
  end

  test 'signed in navbar omits guest login link' do
    sign_in users(:user_one)

    get fictions_path

    assert_select 'nav a[href=?]', new_user_session_path, count: 0
  end

  test 'signed in studio navbar includes auth dropdown for morph parity' do
    sign_in users(:user_one)

    get studio_index_path

    assert_response :success
    assert_select 'nav #user-dropdown'
  end

  test 'signed in navbar renders the three catalog links' do
    sign_in users(:user_one)

    get fictions_path

    assert_select 'nav[aria-label="Основна навігація"] a[href=?]', fictions_path, text: 'Ранобе'
    assert_select 'nav[aria-label="Основна навігація"] a[href=?]', calendar_fictions_path, text: 'Календар'
    assert_select 'nav[aria-label="Основна навігація"] a[href=?]', alphabetical_fictions_path, text: 'Сховище'
  end

  test 'signed in navbar omits retired mega-menu labels' do
    sign_in users(:user_one)

    get fictions_path

    assert_select 'nav[aria-label="Основна навігація"]', text: /Блоги|Відео|Переклад/, count: 0
  end

  test 'navbar keeps toolbar before nav links in dom order' do
    get fictions_path

    assert_response :success
    assert_operator response.body.index('eCommerceSearchModalButton'),
                    :<,
                    response.body.index('aria-label="Основна навігація"')
  end
end
