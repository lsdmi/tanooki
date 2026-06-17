# frozen_string_literal: true

module Search
  # Searchkick queries, pagination, and turbo section rendering for SearchController#index.
  module IndexQuery
    extend ActiveSupport::Concern
    include Search::IndexPagination
    include Search::IndexTurboStreams

    OPENSEARCH_CONNECTION_ERRORS = [
      Faraday::Error,
      Errno::ECONNREFUSED,
      SocketError,
      Timeout::Error,
      OpenSearch::Transport::Transport::Error
    ].freeze

    private

    def load_search_results
      load_search_pagy_results
      assign_search_collections
      load_search_sidebar_tags
    end

    def load_search_pagy_results
      @pagy_fictions, @fiction_records = pagy_searchkick_for(fiction_search, limit: fiction_per_page)
      @pagy_results, @publication_records = pagy_searchkick_for(publication_search, limit: publication_per_page)
      @pagy_videos, @video_records = pagy_searchkick_for(video_search, limit: video_per_page)
    end

    def assign_search_collections
      @fictions = show_fictions? ? @fiction_records : []
      @results = show_publications? ? @publication_records : []
      @videos = show_videos? ? @video_records : []
    end

    def load_search_sidebar_tags
      @trending_tag_labels = trending_tag_labels_for_sidebar
      @trending_tag_counts = search_tag_counts(@trending_tag_labels)
    end

    def transformed_param
      return nil if params[:search].blank?

      params[:search] = Array(params[:search])
    end

    def fiction_search
      Fiction.pagy_searchkick(
        params[:search],
        fields: ['title^2', 'alternative_title', 'author', 'english_title', 'scanlators']
      ).includes(cover_attachment: :blob)
    end

    def publication_search
      Publication.pagy_searchkick(
        params[:search],
        fields: ['tags^10', 'title^5', 'description'],
        boost_by_recency: { created_at: { scale: '7d', decay: 0.9 } }
      ).includes(:rich_text_description, :cover_attachment)
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

    def trending_tag_labels_for_sidebar
      trending_tags.filter_map { |tag| tag[:name].presence }
    end
  end
end
