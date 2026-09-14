# frozen_string_literal: true

require 'test_helper'

class FlashToastLayoutTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'redirect notice uses hidden flash frames' do
    create_bookshelf_with_notice

    assert_response :success
    assert_select 'turbo-frame#application-notice.hidden'
    assert_select 'turbo-frame#application-alert.hidden'
  end

  test 'redirect notice wires flash-toast payload' do
    create_bookshelf_with_notice

    assert_select(
      '#application-notice [data-controller="flash-toast"][data-flash-toast-type-value="notice"]' \
      '[data-flash-toast-message-value="Полицю дадано"]'
    )
  end

  test 'redirect notice omits banner markup' do
    create_bookshelf_with_notice

    assert_select '#toast-default', count: 0
    assert_select '#toast-warning', count: 0
  end

  test 'registration alert wires flash-toast payload' do
    submit_invalid_registration

    assert_response :unprocessable_entity
    assert_select(
      '#application-alert [data-controller="flash-toast"][data-flash-toast-type-value="alert"]' \
      '[data-flash-toast-message-value="Перевірте та виправте форму реєстрації:"]'
    )
  end

  test 'registration alert omits banner markup' do
    submit_invalid_registration

    assert_select '#toast-default', count: 0
    assert_select '#toast-warning', count: 0
  end

  private

  def create_bookshelf_with_notice
    sign_in users(:user_one)
    fiction = fictions(:one)

    post bookshelves_url, params: {
      bookshelf: {
        title: 'Flash toast shelf',
        description: 'Test shelf',
        fiction_ids: [fiction.id]
      }
    }
    follow_redirect!
  end

  def submit_invalid_registration
    post register_path, params: {
      user: {
        avatar_id: 1,
        email: 'flash-toast@example.com',
        name: '',
        password: 'password',
        password_confirmation: 'password'
      }
    }
  end
end
