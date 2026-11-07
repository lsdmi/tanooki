# frozen_string_literal: true

require 'test_helper'

module Admin
  class ContestsFormTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      sign_in users(:user_one)
    end

    test 'edit form uses the text editor for theme and rules' do
      get edit_admin_contest_url(contests(:draft))

      assert_response :success
      assert_select 'textarea.tinymce#contest_description'
      assert_select 'textarea.tinymce#contest_rules'
    end
  end
end
