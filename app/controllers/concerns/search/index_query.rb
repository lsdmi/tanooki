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
      timings = {}
      load_search_pagy_results(timings)
      assign_search_collections(timings)
      load_search_sidebar_tags
      log_search_timings(timings)
    end

    def load_search_pagy_results(timings)
      # Filtered tabs used to still hit OpenSearch three times (limit 1 on the hidden ones). Skip those.
      @pagy_fictions, @fiction_records = search_section(:fictions, timings) { fiction_search }
      @pagy_results, @publication_records = search_section(:publications, timings) { publication_search }
      @pagy_videos, @video_records = search_section(:videos, timings) { video_search }
    end

    def search_section(name, timings)
      limit = send(:"#{name == :publications ? :publication : name.to_s.singularize}_per_page")
      show = send(:"show_#{name}?")
      unless show
        timings[:"os_#{name}"] = 0.0
        return [empty_search_pagy(limit), []]
      end

      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      result = pagy_searchkick_for(yield, limit:)
      timings[:"os_#{name}"] = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
      result
    end

    def assign_search_collections(timings)
      @fictions = @fiction_records
      @results = @publication_records
      @videos = @video_records
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      # Searchkick's chained includes is not always applied to the hydrated rows; cover cards need the blob.
      ActiveRecord::Associations::Preloader.new(records: @fictions, associations: { cover_attachment: :blob }).call
      ActiveRecord::Associations::Preloader.new(records: @results, associations: { cover_attachment: :blob }).call
      timings[:sql_hydrate] = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
    end

    def log_search_timings(timings)
      Rails.logger.info(
        '[search.timing] ' \
        "os_fictions=#{ms(timings[:os_fictions])} os_publications=#{ms(timings[:os_publications])} " \
        "os_videos=#{ms(timings[:os_videos])} sql_hydrate=#{ms(timings[:sql_hydrate])} " \
        "filter=#{params[:filter].presence || 'all'}"
      )
    end

    def ms(seconds)
      ((seconds || 0) * 1000).round
    end

    def load_search_sidebar_tags
      @trending_tag_labels = trending_tag_labels_for_sidebar
      @trending_tag_counts = search_tag_counts(@trending_tag_labels)
    end

    # Links from outside sometimes send search[0]=..., which Rails parses as a hash rather than an array.
    def transformed_param
      terms = params[:search]
      terms = terms.values if terms.is_a?(ActionController::Parameters)
      terms = Array(terms).grep(String).compact_blank
      return nil if terms.empty?

      params[:search] = terms
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

    def trending_tag_labels_for_sidebar
      trending_tags.filter_map { |tag| tag[:name].presence }
    end
  end
end
