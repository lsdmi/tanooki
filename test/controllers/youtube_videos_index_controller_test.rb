# frozen_string_literal: true

require 'test_helper'

class YoutubeVideosIndexControllerTest < ActionDispatch::IntegrationTest
  test 'should get index' do
    Search::TagCounts.stub(:call, {}) do
      get youtube_videos_path
    end

    assert_response :success
    verify_youtube_videos_index_assigns

    assert_equal({}, assigns(:video_tag_counts))
  end

  test 'index omits legacy banners outside development' do
    Search::TagCounts.stub(:call, {}) do
      get youtube_videos_path
    end

    assert_response :success
    assert_select '[id^="advertisement-banner-"]', count: 0
    assert_select '.youtube-index__ad', count: 0
  end

  test 'index renders adsense slot preview in development' do
    Rails.stub(:env, ActiveSupport::StringInquirer.new('development')) do
      Search::TagCounts.stub(:call, {}) do
        get youtube_videos_path
      end

      assert_response :success
      assert_select 'section.youtube-index__ad #adsense-slot-youtube_index-index.reader-ad-slot--preview',
                    count: 1
    end
  end

  test 'index sections do not repeat the same YouTube video_id' do
    Search::TagCounts.stub(:call, {}) do
      get youtube_videos_path
    end

    video_ids = [
      assigns(:highlight)&.video_id,
      *Array(assigns(:popular)).map(&:video_id),
      *Array(assigns(:latest)).map(&:video_id),
      *Array(assigns(:other_youtube_videos)).map(&:video_id)
    ].compact

    assert_equal video_ids.size, video_ids.uniq.size
  end

  test 'index reuses homepage editorial video layout' do
    Search::TagCounts.stub(:call, {}) do
      get youtube_videos_path
    end

    assert_select 'section.youtube-index__hero iframe[src*="youtube.com/embed"]', count: 2
    assert_select 'section.youtube-index__hero turbo-frame#video-list.contents'
    assert_select 'section.youtube-index__hero turbo-frame#video-list-mobile'
  end

  test 'index sidebar pagination supports three videos per page' do
    Search::TagCounts.stub(:call, {}) do
      get youtube_videos_path
    end

    assert_select 'section.youtube-index__hero .youtube-index__pagination'
    assert_operator assigns(:other_youtube_videos).size, :<=, Root::VideosHelper::SUPPORTING_VIDEO_COUNT
  end

  test 'index paginated sidebar responds to turbo frame request' do
    Search::TagCounts.stub(:call, {}) do
      get youtube_videos_path(page: 2), headers: { 'Turbo-Frame' => 'video-list' }
    end

    assert_response :success
    assert_select 'turbo-frame#video-list'
    assert_select 'section.my-10', count: 0
  end

  test 'index mobile paginated list responds to turbo frame request' do
    Search::TagCounts.stub(:call, {}) do
      get youtube_videos_path(page: 2), headers: { 'Turbo-Frame' => 'video-list-mobile' }
    end

    assert_response :success
    assert_select 'turbo-frame#video-list-mobile'
    assert_select 'section.my-10', count: 0
  end

  private

  def verify_youtube_videos_index_assigns
    assert_not_nil assigns(:popular)
    assert_not_nil assigns(:latest)
    assert_not_nil assigns(:pagy)
    assert_not_nil assigns(:other_youtube_videos)
  end
end
