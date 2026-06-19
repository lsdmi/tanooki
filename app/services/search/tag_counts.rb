# frozen_string_literal: true

module Search
  # Returns { "аніме" => 12, "fantasy" => 3 } for tag labels.
  # Counts are cached per tag + scope to avoid hammering OpenSearch.
  class TagCounts
    SCOPES = %i[all videos publications fictions].freeze
    CACHE_TTL = 6.hours
    HOME_YOUTUBE_TAG_LIMIT = 5
    INDEX_LATEST_YOUTUBE_TAG_LIMIT = 2
    INDEX_HIGHLIGHT_YOUTUBE_TAG_LIMIT = 5

    OPENSEARCH_CONNECTION_ERRORS = [
      Faraday::Error,
      Errno::ECONNREFUSED,
      SocketError,
      Timeout::Error
    ].freeze

    def self.call(tags, scope: :all)
      new(tags, scope: scope).call
    end

    def self.labels_from_youtube_videos(videos, limit:)
      Array(videos).flat_map { |video| labels_from_youtube_video(video, limit: limit) }.uniq
    end

    def self.labels_from_youtube_video(video, limit:)
      return [] unless video&.tags?

      video.tags.split(', ').first(limit)
    end

    def self.labels_from_publications(publications)
      Array(publications).flat_map { |publication| publication.tags.map(&:name) }.uniq
    end

    def initialize(tags, scope: :all)
      @tags = Array(tags).map(&:to_s).compact_blank.uniq
      @scope = scope.to_sym
      raise ArgumentError, "unknown scope: #{@scope}" unless SCOPES.include?(@scope)
    end

    def call
      return publication_counts if scope == :publications

      tags.index_with { |tag| count_for(tag) }
    end

    private

    attr_reader :tags, :scope

    def count_for(tag)
      Rails.cache.fetch(cache_key(tag), expires_in: CACHE_TTL) do
        fetch_count(tag)
      end
    rescue *OPENSEARCH_CONNECTION_ERRORS => e
      Rails.logger.warn("[search/tag_counts] OpenSearch unavailable for #{tag}: #{e.class}")
      nil
    end

    def cache_key(tag)
      "search/tag_counts/#{scope}/#{tag.to_s.parameterize}"
    end

    def publication_counts
      Rails.cache.fetch(publication_batch_cache_key, expires_in: CACHE_TTL) do
        grouped = Tag.joins(:publications).where(name: tags).group(:name).count
        tags.index_with { |tag| grouped.fetch(tag, 0) }
      end
    end

    def publication_batch_cache_key
      digest = Digest::SHA256.hexdigest(tags.map { |tag| tag.to_s.parameterize }.sort.join('|'))
      "search/tag_counts/publications/batch/#{digest}"
    end

    def fetch_count(tag)
      case scope
      when :all then count_all(tag)
      when :videos then count_search(YoutubeVideo, tag, video_fields)
      when :publications then publication_count_for(tag)
      when :fictions then count_search(Fiction, tag, fiction_fields)
      end
    end

    def count_all(tag)
      count_search(Fiction, tag, fiction_fields) +
        count_search(Publication, tag, publication_fields) +
        count_search(YoutubeVideo, tag, video_fields)
    end

    def publication_count_for(tag)
      Tag.joins(:publications).where(name: tag).count
    end

    def count_search(model, tag, fields)
      model.search(
        tag,
        fields: fields,
        load: false,
        limit: 0
      ).total_count
    end

    def fiction_fields
      ['title^2', 'alternative_title', 'author', 'english_title', 'scanlators']
    end

    def publication_fields
      ['tags^10', 'title^5', 'description']
    end

    def video_fields
      ['title^2', 'description', 'tags']
    end
  end
end
