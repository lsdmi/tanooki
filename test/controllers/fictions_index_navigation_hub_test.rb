# frozen_string_literal: true

require 'test_helper'

class FictionsIndexNavigationHubTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'renders closing hub after the writings promo' do
    get fictions_path

    assert_operator response.body.index('Сховище, календар і читальня'),
                    :>,
                    response.body.index('Писальня та запит на переклад')
  end

  test 'renders the three hub card titles' do
    get fictions_path

    assert_select '[aria-label="Сховище, календар і читальня"]', text: /Сховище/
    assert_select '[aria-label="Сховище, календар і читальня"]', text: /Календар/
    assert_select '[aria-label="Сховище, календар і читальня"]', text: /Читальня/
  end

  test 'guest library CTA links to login' do
    get fictions_path

    assert_select '[aria-label="Сховище, календар і читальня"] a[href=?]',
                  new_user_session_path,
                  text: /Увійти до читальні/
  end

  test 'signed-in library CTA links to library' do
    sign_in users(:user_one)

    get fictions_path

    assert_select '[aria-label="Сховище, календар і читальня"] a[href=?]',
                  library_path,
                  text: /Відкрити читальню/
  end
end
