# frozen_string_literal: true

require 'test_helper'

class AuthPagesRobotsTest < ActionDispatch::IntegrationTest
  test 'account pages are kept out of search results' do
    [new_user_session_path, register_path, new_user_password_path].each do |path|
      get path

      assert_select 'meta[name="robots"][content="noindex, follow"]', { count: 1 }, path
    end
  end

  test 'content pages stay indexable' do
    get root_path

    assert_select 'meta[name="robots"][content="max-image-preview:large"]', count: 1
  end

  test 'sign-in page has a text-only Google button' do
    get new_user_session_path

    assert_select '#sign-in-with-google svg', count: 0
    assert_select 'input[type="submit"]#sign-in-with-google[value="Увійти через Google"], ' \
                  'button#sign-in-with-google', count: 1
  end

  test 'sign-in page uses a neutral email placeholder' do
    get new_user_session_path

    assert_select 'input[type="email"][placeholder="email@example.com"]', count: 1
    assert_not_includes response.body, 'user@baka.in.ua'
  end
end
