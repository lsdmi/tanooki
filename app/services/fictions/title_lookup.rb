# frozen_string_literal: true

module Fictions
  # Top title matches for the new-fiction form. Search stays on the fields already indexed
  # in Fiction#search_data. A dead search index returns no suggestions instead of an error.
  class TitleLookup
    LIMIT = 5
    MIN_QUERY_LENGTH = 2
    FIELDS = ['title^2', 'alternative_title', 'english_title'].freeze
    SEARCH_ERRORS = [
      Searchkick::Error,
      Faraday::Error,
      Errno::ECONNREFUSED,
      SocketError,
      Timeout::Error,
      OpenSearch::Transport::Transport::Error
    ].freeze

    def initialize(query)
      @query = query.to_s.strip
    end

    def call
      return [] if query.length < MIN_QUERY_LENGTH

      search_matches
    rescue *SEARCH_ERRORS => e
      Rails.logger.warn("[fictions] title lookup failed: #{e.class}: #{e.message}")
      []
    end

    private

    attr_reader :query

    def search_matches
      Fiction.search(
        query,
        fields: FIELDS,
        limit: LIMIT,
        where: Fiction.searchkick_active_where,
        includes: [:scanlators, { cover_attachment: :blob }]
      ).to_a
    end
  end
end
