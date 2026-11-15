# frozen_string_literal: true

require 'test_helper'

module Root
  class HomeVideosTest < ActiveSupport::TestCase
    setup do
      Rails.cache.delete(HomeVideos::CACHE_KEY)
      Rails.cache.delete('home_videos/v1')
    end

    test 'returns four videos ordered by views when last month has enough' do
      videos = HomeVideos.call

      assert_equal Root::VideosHelper::HOME_VIDEO_LIMIT, videos.size
      assert_equal [400, 300, 200, 100], videos.map(&:views)
    end

    test 'pads with newest when last month alone is short' do
      youtube_videos(:three).update!(
        published_at: 2.months.ago,
        views: 50,
        description: 'Video three for home padding.'
      )
      youtube_videos(:four).update!(
        published_at: 2.months.ago,
        views: 40,
        description: 'Video four for home padding.'
      )
      Rails.cache.delete(HomeVideos::CACHE_KEY)

      videos = HomeVideos.call
      expected = %i[one two three four].map { |key| youtube_videos(key).id }.sort

      assert_equal Root::VideosHelper::HOME_VIDEO_LIMIT, videos.size
      assert_equal expected, videos.map(&:id).sort
    end

    test 'backfills when a cached video was soft-deleted' do
      filler = YoutubeVideo.create!(
        slug: 'home-videos-filler',
        youtube_channel: youtube_channels(:one),
        video_id: 'home-videos-filler',
        title: 'Filler Video',
        thumbnail: 'https://example.com/videos/filler.jpg',
        tags: 'filler',
        views: 1,
        published_at: 3.days.ago,
        description: 'Extra video for home-section backfill.'
      )

      HomeVideos.call
      cached = Rails.cache.read(HomeVideos::CACHE_KEY)

      assert_equal(
        [Root::VideosHelper::HOME_VIDEO_LIMIT, false],
        [cached.size, cached.include?(filler.id)]
      )

      YoutubeVideo.find(cached.last).destroy
      videos = HomeVideos.call

      assert_equal(
        [Root::VideosHelper::HOME_VIDEO_LIMIT, true, true],
        [videos.size, videos.map(&:id).include?(filler.id), videos.none?(&:deleted?)]
      )
    end
  end
end
