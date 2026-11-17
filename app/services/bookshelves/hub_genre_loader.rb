# frozen_string_literal: true

module Bookshelves
  # Top genres per shelf by fiction membership count for hub cards.
  class HubGenreLoader
    def self.call(bookshelf_ids, limit: HubPreview::TOP_GENRES)
      new(bookshelf_ids, limit:).call
    end

    def initialize(bookshelf_ids, limit:)
      @bookshelf_ids = Array(bookshelf_ids)
      @limit = limit
    end

    def call
      return {} if @bookshelf_ids.empty?

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
                  .where(bookshelf_fictions: { bookshelf_id: @bookshelf_ids })
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
