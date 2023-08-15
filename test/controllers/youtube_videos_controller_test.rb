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
end
