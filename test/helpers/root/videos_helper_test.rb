# frozen_string_literal: true

require 'test_helper'

module Root
  class VideosHelperTest < ActionView::TestCase
    include VideosHelper

    test 'home_videos_editorial_cards partitions first video as featured and next three as supporting' do
      videos = [
        youtube_videos(:one),
        youtube_videos(:two),
        youtube_videos(:three),
        youtube_videos(:four)
      ]

      assert_equal(
        { featured: videos.first, supporting: videos.last(3) },
        home_videos_editorial_cards(videos)
      )
    end

    test 'home_videos_editorial_cards returns empty supporting when only featured exists' do
      video = youtube_videos(:one)

      assert_equal(
        { featured: video, supporting: [] },
        home_videos_editorial_cards([video])
      )
    end

    test 'home_videos_editorial_cards returns empty slots for blank input' do
      assert_equal(
        { featured: nil, supporting: [] },
        home_videos_editorial_cards([])
      )
    end

    test 'home_featured_video_poster_url uses maxres for YouTube thumbs' do
      video = youtube_videos(:one)
      video.thumbnail = 'https://i.ytimg.com/vi/abc123/sddefault.jpg'

      assert_equal "https://i.ytimg.com/vi/#{video.video_id}/maxresdefault.jpg", home_featured_video_poster_url(video)
    end

    test 'home_featured_video_poster_url keeps a non-YouTube stored cover' do
      video = youtube_videos(:one)
      video.thumbnail = 'https://cdn.example/cover.webp'

      assert_equal 'https://cdn.example/cover.webp', home_featured_video_poster_url(video)
    end

    test 'home_featured_video_poster_url falls back to maxres when thumbnail is blank' do
      video = youtube_videos(:one)
      video.thumbnail = ''

      assert_equal "https://i.ytimg.com/vi/#{video.video_id}/maxresdefault.jpg", home_featured_video_poster_url(video)
    end

    test 'home_featured_video_fallback_poster_url is the letterboxed sddefault' do
      video = youtube_videos(:one)
      expected = "https://i.ytimg.com/vi/#{video.video_id}/sddefault.jpg"

      assert_equal expected, home_featured_video_fallback_poster_url(video)
    end
  end
end
