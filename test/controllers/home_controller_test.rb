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

  test 'highlights should return up to 3 publication highlights and fill in with tales' do
    highlights = Publication.highlights.order(created_at: :desc).first(3)

    tales_count = [3 - highlights.size, 0].max
    expected_highlights = highlights + Tale.not_highlights.order(created_at: :desc).first(tales_count)
    assert_equal expected_highlights, @controller.send(:highlights)
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
