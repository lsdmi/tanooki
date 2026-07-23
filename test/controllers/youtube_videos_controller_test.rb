# frozen_string_literal: true

require 'test_helper'

class YoutubeVideosControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @youtube_video = youtube_videos(:one)
  end

  test 'should get show' do
    Search::TagCounts.stub(:call, { 'one' => 5 }) do
      get youtube_video_path(@youtube_video)
    end

    assert_response :success
    assert_equal ['one'], assigns(:video_tags)
    assert_equal({ 'one' => 5 }, assigns(:video_tag_counts))
  end

  test 'show does not render legacy advertisement banner' do
    Search::TagCounts.stub(:call, {}) do
      get youtube_video_path(@youtube_video)
    end

    assert_response :success
    assert_select '[id^="advertisement-banner-"]', count: 0
    assert_select '.youtube-show__ad', count: 1
  end

  test 'show loads up to three related videos from the same channel' do
    Search::TagCounts.stub(:call, {}) do
      get youtube_video_path(@youtube_video)
    end

    assert_response :success
    assert_equal 3, assigns(:more_videos).size
    assert_select '.youtube-show__related-item', count: 3
  end

  test 'show loads two related videos in development' do
    Rails.stub(:env, ActiveSupport::StringInquirer.new('development')) do
      Search::TagCounts.stub(:call, {}) do
        get youtube_video_path(@youtube_video)
      end

      assert_response :success
      assert_equal 2, assigns(:more_videos).size
      assert_select '.youtube-show__related-item', count: 2
    end
  end

  test 'show renders adsense slot preview in development' do
    Rails.stub(:env, ActiveSupport::StringInquirer.new('development')) do
      Search::TagCounts.stub(:call, {}) do
        get youtube_video_path(@youtube_video)
      end

      assert_response :success
      assert_select '.youtube-show__ad ' \
                    "#adsense-slot-youtube_video-#{@youtube_video.id}.reader-ad-slot--preview", count: 1
    end
  end

  test 'show returns not found for missing video' do
    get youtube_video_path('missing-video-slug')

    assert_response :not_found
  end

  test 'should get index' do
    Search::TagCounts.stub(:call, {}) do
      get youtube_videos_path
    end

    assert_response :success
    verify_youtube_videos_index_assigns

    assert_equal({}, assigns(:video_tag_counts))
  end

  private

  def verify_youtube_videos_index_assigns
    assert_not_nil assigns(:popular)
    assert_not_nil assigns(:latest)
    assert_not_nil assigns(:pagy)
    assert_not_nil assigns(:other_youtube_videos)
  end
end
