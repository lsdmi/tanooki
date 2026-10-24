# frozen_string_literal: true

module ContentFilters
  # SQL and search clauses for a Preference. Kept beside the value object so the class stays small.
  module PreferenceExclusion
    private

    def cap_rating(scope)
      return scope if max_rating.nil?

      scope.where(content_rating: ..max_rating)
    end

    def drop_hidden_genres(scope)
      return scope if hidden_genre_ids.empty?

      scope.where.not(id: FictionGenre.where(genre_id: hidden_genre_ids).select(:fiction_id))
    end

    def drop_plain_romance(scope)
      romance_id = Packages.romance_id
      return scope unless hides_plain_romance? && romance_id

      has_romance = FictionGenre.where(genre_id: romance_id).select(:fiction_id)
      scope.where.not(id: plain_romance_ids(has_romance))
    end

    def plain_romance_ids(has_romance)
      excluded = Fiction.where(id: has_romance)
      premise_ids = Packages.premise_ids
      return excluded.select(:id) if premise_ids.empty?

      flavored = FictionGenre.where(genre_id: premise_ids).select(:fiction_id)
      excluded.where.not(id: flavored).select(:id)
    end

    def opened_romance_keys(genre_id)
      return package_keys unless genre_id == Packages.romance_id

      package_keys.without(Packages::PLAIN_ROMANCE).freeze
    end

    def plain_romance?(ids)
      romance_id = Packages.romance_id
      return false unless hides_plain_romance? && romance_id

      ids.include?(romance_id) && !ids.intersect?(Packages.premise_ids)
    end

    def hides_plain_romance?
      package_keys.include?(Packages::PLAIN_ROMANCE)
    end

    def rating_and_genre_where
      {}.tap do |where|
        where[:content_rating] = { lte: max_rating } unless max_rating.nil?
        where[:_not] = { genre_ids: hidden_genre_ids } if hidden_genre_ids.any?
      end
    end

    def plain_romance_clause
      romance_id = Packages.romance_id
      keeps = Packages.premise_ids.map { |id| { genre_ids: [id] } }
      return { _not: { genre_ids: [romance_id] } } if keeps.empty?

      { _or: [{ _not: { genre_ids: [romance_id] } }, *keeps] }
    end
  end
end
