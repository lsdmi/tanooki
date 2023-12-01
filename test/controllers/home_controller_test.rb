# frozen_string_literal: true

require 'test_helper'

class HomeControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @controller = HomeController.new
  end

  test 'should get index' do
    get root_url
    assert_response :success
  end
end
