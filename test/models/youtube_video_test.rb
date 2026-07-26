# frozen_string_literal: true

require 'test_helper'

class YoutubeVideoTest < ActiveSupport::TestCase
  test 'excluding_video removes every row that shares the same YouTube video_id' do
    video = youtube_videos(:one)
    duplicate = YoutubeVideo.create!(
      slug: 'one-duplicate',
      youtube_channel: video.youtube_channel,
      video_id: video.video_id,
      title: video.title,
      thumbnail: video.thumbnail,
      tags: video.tags,
      views: video.views,
      published_at: video.published_at,
      description: 'Duplicate import of the same YouTube upload.'
    )

    results = YoutubeVideo.excluding_video(video)

    assert_not_includes results, video
    assert_not_includes results, duplicate
  end

  test 'one_per_video keeps a single row for each YouTube video_id' do
    video = youtube_videos(:one)
    duplicate = YoutubeVideo.create!(
      slug: 'one-duplicate',
      youtube_channel: video.youtube_channel,
      video_id: video.video_id,
      title: video.title,
      thumbnail: video.thumbnail,
      tags: video.tags,
      views: video.views,
      published_at: video.published_at,
      description: 'Duplicate import of the same YouTube upload.'
    )

    results = YoutubeVideo.one_per_video.where(video_id: video.video_id)

    assert_equal [duplicate.id], results.pluck(:id)
  end
end
