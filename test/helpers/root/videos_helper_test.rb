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
  end
end
