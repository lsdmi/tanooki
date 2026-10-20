# frozen_string_literal: true

require 'test_helper'

class FictionsIndexNavigationHubTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'renders closing hub with writings storage and calendar' do
    get fictions_path

    assert_select '[aria-label="Писальня, сховище і календар"]'
    assert_select '[aria-label="Сховище, календар і читальня"]', count: 0
    assert_select '.fiction-genre-writings-banner', count: 0
  end

  test 'renders the three hub card titles in order' do
    get fictions_path

    titles = css_select('[aria-label="Писальня, сховище і календар"] h3').map { |node| node.text.strip }

    assert_equal ['Твори із Бакою', 'Сховище', 'Календар'], titles
  end

  test 'hub omits the library card' do
    get fictions_path

    assert_select '[aria-label="Писальня, сховище і календар"]', text: /Читальня/, count: 0
  end

  test 'guest writings CTA links to login' do
    get fictions_path

    assert_select '[aria-label="Писальня, сховище і календар"] a[href=?]',
                  new_user_session_path,
                  text: /Увійти та почати писати/
  end

  test 'signed-in writings CTA links to studio writings' do
    sign_in users(:user_one)

    get fictions_path

    assert_select '[aria-label="Писальня, сховище і календар"] a[href=?]',
                  readings_path,
                  text: /Відкрити писальню/
  end
end
