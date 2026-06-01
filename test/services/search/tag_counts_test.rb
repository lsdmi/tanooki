# frozen_string_literal: true

require 'test_helper'

module Search
  class TagCountsTest < ActiveSupport::TestCase
    setup do
      Rails.cache.clear
    end

    test 'returns empty hash for blank tags' do
      assert_empty(TagCounts.call([]))
    end

    test 'sums counts across models for :all scope' do
      with_stubbed_counts(fiction: 2, publication: 3, video: 7) do
        assert_equal({ 'аніме' => 12 }, TagCounts.call(['аніме'], scope: :all))
      end
    end

    test 'returns nil when OpenSearch is unavailable' do
      Fiction.stub(:search, ->(*) { raise Faraday::ConnectionFailed, 'down' }) do
        assert_nil TagCounts.call(['аніме'], scope: :fictions)['аніме']
      end
    end

    test 'rejects unknown scope' do
      assert_raises(ArgumentError) do
        TagCounts.new(['аніме'], scope: :unknown)
      end
    end

    test 'labels_from_youtube_videos collects unique tag labels' do
      video = youtube_videos(:one)
      video.tags = 'аніме, fantasy, аніме'

      labels = TagCounts.labels_from_youtube_videos([video, video], limit: 2)

      assert_equal %w[аніме fantasy], labels
    end

    test 'home youtube tag limit matches labels shown on home videos' do
      video = youtube_videos(:one)
      video.tags = (1..6).map { |index| "tag#{index}" }.join(', ')

      labels = TagCounts.labels_from_youtube_video(video, limit: TagCounts::HOME_YOUTUBE_TAG_LIMIT)

      assert_equal %w[tag1 tag2 tag3 tag4 tag5], labels
    end

    test 'labels_from_publications collects tag names' do
      publication = publications(:tale_approved_one)

      assert_includes TagCounts.labels_from_publications(publication), tags(:one).name
    end

    private

    def with_stubbed_counts(fiction:, publication:, video:, &)
      Fiction.stub(:search, search_result(fiction)) do
        Publication.stub(:search, search_result(publication)) do
          YoutubeVideo.stub(:search, search_result(video), &)
        end
      end
    end

    def search_result(total_count)
      ->(*) { [].tap { |r| r.define_singleton_method(:total_count) { total_count } } }
    end
  end
end
