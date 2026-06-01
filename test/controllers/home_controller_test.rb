# frozen_string_literal: true

require 'test_helper'

class HomeControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @controller = HomeController.new
  end

  test 'should get index' do
    Search::TagCounts.stub(:call, {}) do
      get root_url
    end

    assert_response :success
    assert_equal({}, assigns(:video_tag_counts))
  end
end
