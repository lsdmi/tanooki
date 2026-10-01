# frozen_string_literal: true

require 'test_helper'

module Youtube
  class SyncChannelVideosTest < ActiveSupport::TestCase
    Response = Struct.new(:items)
    PlaylistItem = Struct.new(:snippet)
    PlaylistItemSnippet = Struct.new(:resource_id)
    ResourceId = Struct.new(:video_id)
    Video = Struct.new(:id, :snippet, :content_details)
    VideoSnippet = Struct.new(:title, :description, :thumbnails, :tags, :published_at)
    ContentDetails = Struct.new(:duration)
    Thumbnails = Struct.new(:maxres)
    Thumbnail = Struct.new(:url)

    setup do
      @channel_id = youtube_channels(:one).channel_id
      @youtube = Google::Apis::YoutubeV3::YouTubeService.new
    end

    test 'call creates a YoutubeVideo for a non-short upload' do
      stub_playlist(%w[new_video])
      lookups = stub_videos([video('new_video', 'PT2M30S')])

      assert_difference('YoutubeVideo.count') { sync }

      assert_equal [['snippet,contentDetails', 'new_video']], lookups
      assert_equal youtube_channels(:one), YoutubeVideo.find_by(video_id: 'new_video').youtube_channel
    end

    test 'call skips the video lookup when every upload is already stored' do
      stub_playlist([youtube_videos(:one).video_id, youtube_videos(:two).video_id])
      lookups = stub_videos([])

      assert_no_difference('YoutubeVideo.count') { sync }

      assert_empty lookups
    end

    test 'call looks up only unknown uploads in one request and skips shorts' do
      stub_playlist([youtube_videos(:one).video_id, 'short_video', 'long_video'])
      lookups = stub_videos([video('short_video', 'PT45S'), video('long_video', 'PT10M')])

      sync

      assert_equal [['snippet,contentDetails', 'short_video,long_video']], lookups
      assert YoutubeVideo.exists?(video_id: 'long_video')
      assert_not YoutubeVideo.exists?(video_id: 'short_video')
    end

    private

    def sync
      Google::Apis::YoutubeV3::YouTubeService.stub(:new, @youtube) { SyncChannelVideos.call(@channel_id) }
    end

    def stub_playlist(video_ids)
      items = video_ids.map { |id| PlaylistItem.new(PlaylistItemSnippet.new(ResourceId.new(id))) }
      @youtube.define_singleton_method(:list_playlist_items) { |*_args, **_opts| Response.new(items) }
    end

    def stub_videos(videos)
      lookups = []
      @youtube.define_singleton_method(:list_videos) do |part, id:|
        lookups << [part, id]
        Response.new(videos)
      end
      lookups
    end

    def video(id, duration)
      snippet = VideoSnippet.new('Title', 'Description', Thumbnails.new(Thumbnail.new('thumbnail_url')),
                                 %w[tag1 tag2], Time.zone.now)
      Video.new(id, snippet, ContentDetails.new(duration))
    end
  end
end
