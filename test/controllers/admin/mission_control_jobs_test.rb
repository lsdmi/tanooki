# frozen_string_literal: true

require 'test_helper'

module Admin
  class MissionControlJobsTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    test 'an admin sees the job dashboard' do
      sign_in users(:user_one)

      get '/admin/jobs'
      follow_redirect! while response.redirect?

      assert_response :success
    end

    test 'a guest is sent to sign in' do
      get '/admin/jobs'

      assert_redirected_to '/login'
    end

    test 'a reader who is not an admin gets a 404' do
      sign_in users(:user_two)

      get '/admin/jobs'

      assert_response :not_found
    end
  end
end
