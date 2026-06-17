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

      bookshelf.bookshelf_fictions.destroy_all

      normalized_fiction_ids.each do |fiction_id|
        bookshelf.bookshelf_fictions.create!(fiction_id:)
      end
    end

    private

    attr_reader :bookshelf, :fiction_ids

    def normalized_fiction_ids
      @normalized_fiction_ids ||= Array(fiction_ids).compact_blank.map(&:to_i).uniq
    end
  end
end
