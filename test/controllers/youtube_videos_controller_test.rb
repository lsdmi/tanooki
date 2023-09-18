# frozen_string_literal: true

require 'test_helper'

class YoutubeVideosControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @youtube_video = youtube_videos(:one)
  end

  test 'should get show' do
    get youtube_video_path(@youtube_video)
    assert_response :success
    assert_not_nil assigns(:youtube_video)
    assert_not_nil assigns(:more_videos)
  end

  test 'should get index' do
    get youtube_videos_path
    assert_response :success

    assert_not_nil assigns(:highlights)
    assert_not_nil assigns(:popular)
    assert_not_nil assigns(:latest)
    assert_not_nil assigns(:pagy)
    assert_not_nil assigns(:other_youtube_videos)
  end
end
