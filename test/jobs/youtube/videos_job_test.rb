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
    content_details_struct = Struct.new(:content_details)
    content_details_mini_struct = Struct.new(:duration)
    video_id_struct = Struct.new(:video_id)
    url_struct = Struct.new(:url)

    @fake_search_response = items_struct.new([id_struct.new(video_id_struct.new('video_id'))])
    @thumbnail = maxres_struct.new(url_struct.new('thumbnail_url'))
    @snippet = snippet_struct.new('Title', 'Description', @thumbnail, %w[tag1 tag2], Time.now)
    @fake_video_response = items_struct.new([snippet_mini_struct.new(@snippet)])

    # Create content details response for duration check
    @content_details = content_details_mini_struct.new('PT2M30S') # 2 minutes 30 seconds
    @fake_content_details_response = items_struct.new([content_details_struct.new(@content_details)])
  end

  test 'create_video method should create a new YoutubeVideo' do
    youtube_service = Google::Apis::YoutubeV3::YouTubeService.new

    Google::Apis::YoutubeV3::YouTubeService.stub(:new, youtube_service) do
      youtube_service.stub(
        :list_searches,
        @fake_search_response,
        ['snippet', { channel_id: 'youtube_channel_one', max_results: 5, type: 'video', order: 'date' }]
      ) do
        # Mock list_videos to return different responses based on the first parameter
        fake_video_response = @fake_video_response
        fake_content_details_response = @fake_content_details_response

        youtube_service.define_singleton_method(:list_videos) do |part, options = {}|
          case part
          when 'snippet'
            fake_video_response
          when 'contentDetails'
            fake_content_details_response
          else
            fake_video_response # fallback
          end
        end

        assert_difference('YoutubeVideo.count') do
          @youtube_videos_job.perform('youtube_channel_one')
        end
      end
    end
  end
end
