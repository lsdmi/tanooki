# frozen_string_literal: true

module Bookshelves
  # Top genres per shelf by fiction membership count for hub cards.
  class HubGenreLoader
    def self.call(memberships, limit: HubPreview::TOP_GENRES)
      new(memberships, limit:).call
    end

    def initialize(memberships, limit:)
      @memberships = memberships
      @limit = limit
    end

    def call
      return {} if @memberships.none?

      ranked = Hash.new { |hash, key| hash[key] = [] }
      ranked_rows.each do |bookshelf_id, genre_id, _count|
        bucket = ranked[bookshelf_id]
        next if bucket.size >= @limit

        bucket << genre_id
      end
      ranked
    end

    private

    def ranked_rows
      FictionGenre.joins(fiction: :bookshelf_fictions)
                  .merge(@memberships)
                  .group('bookshelf_fictions.bookshelf_id', 'fiction_genres.genre_id')
                  .order(Arel.sql('COUNT(*) DESC'), 'fiction_genres.genre_id ASC')
                  .pluck(
                    Arel.sql('bookshelf_fictions.bookshelf_id'),
                    Arel.sql('fiction_genres.genre_id'),
                    Arel.sql('COUNT(*)')
                  )
    end
  end
end
