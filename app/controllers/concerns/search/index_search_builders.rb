# frozen_string_literal: true

module Search
  # Searchkick query builders and OpenSearch error handling for SearchController#index.
  module IndexSearchBuilders
    extend ActiveSupport::Concern

    OPENSEARCH_CONNECTION_ERRORS = [
      Faraday::Error,
      Errno::ECONNREFUSED,
      SocketError,
      Timeout::Error,
      OpenSearch::Transport::Transport::Error
    ].freeze
    FICTION_SEARCH_FIELDS = ['title^2', 'alternative_title', 'author', 'english_title', 'scanlators'].freeze

    private

    def fiction_search
      Fiction.pagy_searchkick(params[:search], **fiction_search_options).includes(cover_attachment: :blob)
    end

    def fiction_search_options
      where = current_content_filter.searchkick_where
      { fields: FICTION_SEARCH_FIELDS }.tap { |options| options[:where] = where if where.present? }
    end

    def publication_search
      Publication.pagy_searchkick(
        params[:search],
        fields: ['tags^10', 'title^5', 'description'],
        boost_by_recency: { created_at: { scale: '7d', decay: 0.9 } }
      ).includes(cover_attachment: :blob)
    end

    def video_search
      YoutubeVideo.pagy_searchkick(
        params[:search],
        fields: ['title^2', 'description', 'tags'],
        boost_by_recency: { published_at: { scale: '7d', decay: 0.9 } }
      )
    end

    def pagy_searchkick_for(search_args, limit:)
      pagy_searchkick(search_args, limit: limit, limit_extra: false)
    rescue *OPENSEARCH_CONNECTION_ERRORS => e
      Rails.logger.warn("[search] OpenSearch unavailable: #{e.class}: #{e.message}")
      @search_unavailable = true
      [empty_search_pagy(limit), []]
    end

    def empty_search_pagy(limit)
      Pagy.new(count: 0, page: params[:page] || 1, limit: [limit, 1].max)
    end
  end
end
