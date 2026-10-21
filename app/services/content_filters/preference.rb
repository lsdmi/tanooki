# frozen_string_literal: true

module ContentFilters
  # Immutable list filter. Open matches today's catalogue: no rating cap, no hidden genres.
  Preference = Data.define(:max_rating, :hidden_genre_ids) do
    def self.open
      new(max_rating: nil, hidden_genre_ids: [].freeze)
    end

    def active?
      !max_rating.nil? || hidden_genre_ids.any?
    end

    def fingerprint
      return 'open' unless active?

      digest = Digest::SHA1.hexdigest(hidden_genre_ids.sort.join(','))[0, 8]
      "r#{max_rating || 'x'}-#{digest}"
    end

    def apply(scope)
      scope = scope.where(content_rating: ..max_rating) unless max_rating.nil?
      return scope if hidden_genre_ids.empty?

      scope.where.not(id: FictionGenre.where(genre_id: hidden_genre_ids).select(:fiction_id))
    end

    def searchkick_where
      {}.tap do |where|
        where[:content_rating] = { lte: max_rating } unless max_rating.nil?
        where[:_not] = { genre_ids: hidden_genre_ids } if hidden_genre_ids.any?
      end
    end
  end
end
