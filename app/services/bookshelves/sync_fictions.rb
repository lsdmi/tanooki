# frozen_string_literal: true

module Bookshelves
  # Replaces a bookshelf's fiction links with the submitted id list.
  class SyncFictions
    def self.call(bookshelf:, fiction_ids:)
      new(bookshelf:, fiction_ids:).call
    end

    def initialize(bookshelf:, fiction_ids:)
      @bookshelf = bookshelf
      @fiction_ids = fiction_ids
    end

    def call
      return if normalized_fiction_ids.empty?

      previous_fiction_ids = bookshelf.fictions.pluck(:id)
      replace_membership!
      bust_fiction_show_fragments(previous_fiction_ids)
    end

    private

    attr_reader :bookshelf, :fiction_ids

    def replace_membership!
      bookshelf.bookshelf_fictions.destroy_all
      normalized_fiction_ids.each do |fiction_id|
        bookshelf.bookshelf_fictions.create!(fiction_id:)
      end

      # Bust the fiction-list fragment cache on membership changes.
      bookshelf.fiction_ids = normalized_fiction_ids
      bookshelf.update!(updated_at: Time.current)
    end

    # Guest fiction#show fragment keys on fiction.updated_at («На полицях»).
    # update_all: skip validations/callbacks — membership change only needs a new cache key.
    def bust_fiction_show_fragments(previous_fiction_ids)
      affected_ids = (previous_fiction_ids + normalized_fiction_ids).uniq
      Fiction.where(id: affected_ids).update_all(updated_at: Time.current)
    end

    def normalized_fiction_ids
      @normalized_fiction_ids ||= Array(fiction_ids).compact_blank.map(&:to_i).uniq
    end
  end
end
