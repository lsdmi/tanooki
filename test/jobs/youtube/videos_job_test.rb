# frozen_string_literal: true

require 'test_helper'

class VideosJobTest < ActiveSupport::TestCase
  setup do
    @youtube_videos_job = Youtube::VideosJob.new

    id_struct = Struct.new(:id)
    items_struct = Struct.new(:items)
    maxres_struct = Struct.new(:maxres)
    snippet_struct = Struct.new(:title, :description, :thumbnails, :tags, :published_at)
    snippet_mini_struct = Struct.new(:snippet)
    video_id_struct = Struct.new(:video_id)
    url_struct = Struct.new(:url)

    @fake_search_response = items_struct.new([id_struct.new(video_id_struct.new('video_id'))])
    @thumbnail = maxres_struct.new(url_struct.new('thumbnail_url'))
    @snippet = snippet_struct.new('Title', 'Description', @thumbnail, %w[tag1 tag2], Time.now)
    @fake_video_response = items_struct.new([snippet_mini_struct.new(@snippet)])
  end

  test 'create_video method should create a new YoutubeVideo' do
    youtube_service = Google::Apis::YoutubeV3::YouTubeService.new

    Google::Apis::YoutubeV3::YouTubeService.stub(:new, youtube_service) do
      youtube_service.stub(
        :list_searches,
        @fake_search_response,
        ['snippet', { channel_id: 'youtube_channel_one', max_results: 5, type: 'video', order: 'date' }]
      ) do
        youtube_service.stub(:list_videos, @fake_video_response, ['snippet', { id: 'video_id' }]) do
          assert_difference('YoutubeVideo.count') do
            @youtube_videos_job.perform('youtube_channel_one')
          end
        end
      end
    end
  end
end
