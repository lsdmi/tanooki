# frozen_string_literal: true

require 'test_helper'

module Users
  class OmniauthCallbacksControllerTest < ActionDispatch::IntegrationTest
    setup do
      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
                                                                           'provider' => 'google_oauth2',
                                                                           'uid' => '12345',
                                                                           'info' => {
                                                                             'email' => 'test@example.com',
                                                                             'name' => 'Test User',
                                                                             'email_verified' => true
                                                                           }
                                                                         })
    end

    test 'should handle Google OAuth2 callback successfully' do
      user = users(:user_one)
      User.stub :from_omniauth, user do
        get '/auth/google_oauth2/callback'
        assert_redirected_to root_path
        assert_equal 'Успішно автентифіковано з облікового запису Google.', flash[:notice]
      end
    end

    test 'should handle Google OAuth2 callback failure' do
      # Mock a user with validation errors
      user = User.new
      user.errors.add(:base, 'Some error')
      User.stub :from_omniauth, user do
        get '/auth/google_oauth2/callback'
        assert_redirected_to new_session_path
        assert_equal 'Some error', flash[:alert]
      end
    end

    teardown do
      OmniAuth.config.test_mode = false
      OmniAuth.config.mock_auth[:google_oauth2] = nil
    end
  end
end
