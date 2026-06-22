# frozen_string_literal: true

require 'test_helper'

class DeviseTurboAuthTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  TURBO_HTML_ACCEPT = 'text/vnd.turbo-html, application/xhtml+xml'

  setup do
    @user = users(:user_one)
    @user.update!(password: 'password', password_confirmation: 'password')
  end

  test 'login form omits turbo false' do
    get new_user_session_path

    assert_response :success
    assert_no_match(/turbo:\s*false|data-turbo="false"/, extract_auth_form_html)
  end

  test 'registration form omits turbo false' do
    get register_path

    assert_response :success
    assert_no_match(/turbo:\s*false|data-turbo="false"/, extract_auth_form_html)
  end

  test 'password reset form omits turbo false' do
    get new_user_password_path

    assert_response :success
    assert_no_match(/turbo:\s*false|data-turbo="false"/, extract_auth_form_html)
  end

  test 'google oauth button keeps turbo false for external redirect' do
    get new_user_session_path

    assert_select '#sign-in-with-google[data-turbo="false"]'
  end

  test 'sign in with turbo accept redirects with see other' do
    post user_session_path,
         params: { user: { email: @user.email, password: 'password' } },
         headers: { 'Accept' => TURBO_HTML_ACCEPT }

    assert_response :see_other
  end

  test 'invalid sign up with turbo accept returns unprocessable entity' do
    post register_path,
         params: { user: { email: 'bad@example.com', name: '', password: 'password', password_confirmation: 'password',
                           avatar_id: 1 } },
         headers: { 'Accept' => TURBO_HTML_ACCEPT }

    assert_response :unprocessable_entity
  end

  test 'sign out with turbo accept redirects with see other' do
    sign_in @user

    get destroy_user_session_path, headers: { 'Accept' => TURBO_HTML_ACCEPT }

    assert_response :see_other
  end

  private

  def extract_auth_form_html
    response.body[%r{simple_form.*?</form>}m] || response.body
  end
end
