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

  test 'navbar ranobe link has icon and text variants' do
    get fictions_path

    assert_select 'nav[aria-label="Основна навігація"] a[href=?][aria-label=?]', fictions_path, 'Ранобе' do
      assert_select 'span.sm\\:hidden svg', count: 1
      assert_select 'span.hidden.sm\\:inline', text: 'Ранобе'
    end
  end

  test 'navbar calendar link has icon and text variants' do
    get fictions_path

    assert_select 'nav[aria-label="Основна навігація"] a[href=?][aria-label=?]',
                  calendar_fictions_path, 'Календар' do
      assert_select 'span.sm\\:hidden svg', count: 1
      assert_select 'span.hidden.sm\\:inline', text: 'Календар'
    end
  end

  test 'navbar storage link has icon and text variants' do
    get fictions_path

    assert_select 'nav[aria-label="Основна навігація"] a[href=?][aria-label=?]',
                  alphabetical_fictions_path, 'Сховище' do
      assert_select 'span.sm\\:hidden svg', count: 1
      assert_select 'span.hidden.sm\\:inline', text: 'Сховище'
    end
  end

  test 'navbar tooltips name the primary destinations' do
    get fictions_path

    assert_select 'nav[aria-label="Основна навігація"] [role=tooltip]', text: 'Ранобе'
    assert_select 'nav[aria-label="Основна навігація"] [role=tooltip]', text: 'Календар'
    assert_select 'nav[aria-label="Основна навігація"] [role=tooltip]', text: 'Сховище'
  end

  test 'navbar has no ranobe dropdown or contests link' do
    sign_in users(:user_one)

    get fictions_path

    assert_select 'nav[aria-label="Основна навігація"] #ranobeNavButton', count: 0
    assert_select 'nav[aria-label="Основна навігація"] a[href="/contests"]', count: 0
  end

  test 'signed in navbar omits retired mega-menu labels' do
    sign_in users(:user_one)

    get fictions_path

    assert_select 'nav[aria-label="Основна навігація"]', text: /Блоги|Відео|Переклад/, count: 0
  end

  test 'navbar keeps primary nav before toolbar in dom order' do
    get fictions_path

    assert_response :success
    assert_operator response.body.index('aria-label="Основна навігація"'),
                    :<,
                    response.body.index('eCommerceSearchModalButton')
  end
end
