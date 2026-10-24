# frozen_string_literal: true

module ContentFilters
  # Immutable list filter. Open matches today's catalogue: no rating cap, no hidden genres.
  Preference = Data.define(:max_rating, :hidden_genre_ids, :package_keys) do
    def initialize(max_rating: nil, hidden_genre_ids: [].freeze, package_keys: [].freeze)
      super(
        max_rating:,
        hidden_genre_ids: Array(hidden_genre_ids).freeze,
        package_keys: Array(package_keys).map(&:to_s).freeze
      )
    end

    def self.open
      new
    end

    def active?
      !max_rating.nil? || hidden_genre_ids.any? || package_keys.any?
    end

    def hides_eighteen?
      !max_rating.nil? && max_rating < Fiction.content_ratings.fetch('eighteen')
    end

    # Opening a hidden genre on purpose keeps that genre in the list. The rating cap and the other hidden genres stay.
    def except_genre(genre_id)
      id = genre_id.to_i
      ids = hidden_genre_ids.include?(id) ? (hidden_genre_ids - [id]).freeze : hidden_genre_ids
      keys = opened_romance_keys(id)
      return self if ids == hidden_genre_ids && keys == package_keys

      with(hidden_genre_ids: ids, package_keys: keys)
    end

    def fingerprint
      return 'open' unless active?

      token = "#{hidden_genre_ids.sort.join(',')}|#{package_keys.sort.join(',')}"
      "r#{max_rating || 'x'}-#{Digest::SHA1.hexdigest(token)[0, 8]}"
    end

    def apply(scope)
      scope = cap_rating(scope)
      scope = drop_hidden_genres(scope)
      drop_plain_romance(scope)
    end

    def rejects_genre_ids?(genre_ids)
      ids = Array(genre_ids).map(&:to_i)
      ids.intersect?(hidden_genre_ids) || plain_romance?(ids)
    end

    # How many of these pool ids the filter removed. Both lists are already in memory.
    def dropped_from(pool_ids, visible_ids)
      return 0 unless active?

      pool = Array(pool_ids).map(&:to_i)
      return 0 if pool.empty?

      pool.size - (pool & Array(visible_ids).map(&:to_i)).size
    end

    def searchkick_where
      where = rating_and_genre_where
      return where unless hides_plain_romance?

      clause = plain_romance_clause
      return clause if where.empty?

      { _and: [where, clause] }
    end

    include PreferenceExclusion
  end
end
