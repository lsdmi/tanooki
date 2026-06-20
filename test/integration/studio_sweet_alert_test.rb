# frozen_string_literal: true

require 'test_helper'

class StudioSweetAlertTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:user_one)
  end

  test 'studio blogs tab renders sweet-alert delete buttons' do
    get studio_index_path(tab: 'blogs')

    assert_response :success
    assert_select 'button.sweet-alert-button[data-controller="sweet-alert"]'
  end

  test 'studio blogs tab wires sweet-alert stimulus action and url value' do
    get studio_index_path(tab: 'blogs')

    assert_select 'button.sweet-alert-button[data-action*="sweet-alert#confirm"]'
    assert_select 'button.sweet-alert-button[data-sweet-alert-url-value]'
  end
end
