# frozen_string_literal: true

module Bookshelves
  # Rank cover fictions per shelf by bookmark count for hub cards.
  class HubCoverLoader
    def self.call(bookshelf_ids, limit: HubPreview::COVERS)
      new(bookshelf_ids, limit:).call
    end

    def initialize(bookshelf_ids, limit:)
      @bookshelf_ids = Array(bookshelf_ids)
      @limit = limit
    end

    def call
      return {} if @bookshelf_ids.empty?

      fictions_by_id = Fiction.where(id: ranked_ids.values.flatten)
                              .includes(cover_attachment: :blob)
                              .index_by(&:id)
      ranked_ids.transform_values { |fiction_ids| fiction_ids.filter_map { |id| fictions_by_id[id] } }
    end

    private

    def ranked_ids
      @ranked_ids ||= begin
        ranked = Hash.new { |hash, key| hash[key] = [] }
        ranked_rows.each do |bookshelf_id, fiction_id, _bookmarks|
          bucket = ranked[bookshelf_id]
          next if bucket.size >= @limit

          bucket << fiction_id
        end
        ranked
      end
    end

    def ranked_rows
      cover_scope.group('bookshelf_fictions.bookshelf_id', 'bookshelf_fictions.fiction_id')
                 .order(Arel.sql('bookshelf_fictions.bookshelf_id ASC'),
                        Arel.sql('COUNT(reading_progresses.id) DESC'),
                        Arel.sql('bookshelf_fictions.fiction_id ASC'))
                 .pluck(Arel.sql('bookshelf_fictions.bookshelf_id'),
                        Arel.sql('bookshelf_fictions.fiction_id'),
                        Arel.sql('COUNT(reading_progresses.id)'))
    end

    def cover_scope
      BookshelfFiction.where(bookshelf_id: @bookshelf_ids)
                      .joins(fiction: :cover_attachment)
                      .left_joins(fiction: :readings)
    end
  end
end
