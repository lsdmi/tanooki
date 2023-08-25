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

  test 'most_popular should return the 5 most popular publications from last month, excluding highlights' do
    most_popular = Publication.last_month.order(views: :desc).limit(5).pluck(:id)
    assert_equal most_popular, @controller.send(:most_popular).pluck(:id)
  end

  test 'newest should return the 10 newest publications, excluding highlights and most popular' do
    newest = Publication.order(created_at: :desc).limit(10).pluck(:id)
    assert_equal newest, @controller.send(:newest).pluck(:id)
  end

  test 'remaining should return all publications, excluding highlights, most popular, and newest' do
    expected_remaining_ids = Publication.order(created_at: :desc).pluck(:id)
    assert_equal expected_remaining_ids, @controller.send(:remaining).pluck(:id)
  end
end
