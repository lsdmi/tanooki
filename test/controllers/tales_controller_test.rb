# frozen_string_literal: true

require 'test_helper'

class TalesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @tale = publications(:tale_approved_one)
  end

  def test_index
    get tales_url
    assert_response :success
  end

  def test_show
    get tale_url(@tale)
    assert_response :success
  end

  def test_show_increments_views
    assert_difference('@tale.reload.views') do
      get tale_url(@tale)
    end
  end

  def test_show_tracks_viewed_content
    get tale_url(@tale)
    viewed_content = JSON.parse(cookies[:viewed])
    assert_equal [@tale.slug], viewed_content
  end

  def test_show_limits_viewed_content_to_10
    12.times do |i|
      tale = publications(:tale_approved_one)
      tale.update!(slug: "tale_#{i}")
      get tale_url(tale)
    end

    viewed_content = JSON.parse(cookies[:viewed])
    assert_equal 10, viewed_content.length
    assert_equal 'tale_11', viewed_content.last
  end

  def test_show_does_not_increment_views_for_same_user
    get tale_url(@tale)
    assert_no_difference('@tale.reload.views') do
      get tale_url(@tale)
    end
  end
end
