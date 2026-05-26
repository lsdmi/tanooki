# frozen_string_literal: true

require 'test_helper'

class VideosJobTest < ActiveSupport::TestCase
  setup do
    @youtube_videos_job = Youtube::VideosJob.new

    resource_id_struct = Struct.new(:video_id)
    items_struct = Struct.new(:items)
    maxres_struct = Struct.new(:maxres)
    snippet_struct = Struct.new(:title, :description, :thumbnails, :tags, :published_at)
    snippet_mini_struct = Struct.new(:snippet)
    playlist_item_snippet_struct = Struct.new(:resource_id)
    content_details_struct = Struct.new(:content_details)
    content_details_mini_struct = Struct.new(:duration)
    url_struct = Struct.new(:url)

    @fake_playlist_response = items_struct.new([
                                                 snippet_mini_struct.new(
                                                   playlist_item_snippet_struct.new(resource_id_struct.new('video_id'))
                                                 )
                                               ])
    @thumbnail = maxres_struct.new(url_struct.new('thumbnail_url'))
    @snippet = snippet_struct.new('Title', 'Description', @thumbnail, %w[tag1 tag2], Time.zone.now)
    @fake_video_response = items_struct.new([snippet_mini_struct.new(@snippet)])

    # Create content details response for duration check
    @content_details = content_details_mini_struct.new('PT2M30S') # 2 minutes 30 seconds
    @fake_content_details_response = items_struct.new([content_details_struct.new(@content_details)])
  end

  test 'create_video method should create a new YoutubeVideo' do
    youtube_service = Google::Apis::YoutubeV3::YouTubeService.new

    Google::Apis::YoutubeV3::YouTubeService.stub(:new, youtube_service) do
      youtube_service.stub(
        :list_playlist_items,
        @fake_playlist_response,
        ['snippet', { playlist_id: 'youtube_channel_one', max_results: 5 }]
      ) do
        # Mock list_videos to return different responses based on the first parameter
        fake_video_response = @fake_video_response
        fake_content_details_response = @fake_content_details_response

        youtube_service.define_singleton_method(:list_videos) do |part, _options = {}|
          if part == 'contentDetails'
            fake_content_details_response
          else
            fake_video_response
          end
        end

        assert_difference('YoutubeVideo.count') do
          @youtube_videos_job.perform('youtube_channel_one')
        end
      end
    end
  end
end
