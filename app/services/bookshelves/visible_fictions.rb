# frozen_string_literal: true

module Bookshelves
  # Public shelves drop works the viewer hid. The owner's own shelf stays whole.
  class VisibleFictions
    def self.call(bookshelf:, viewer:, filter:)
      new(bookshelf:, viewer:, filter:).call
    end

    def initialize(bookshelf:, viewer:, filter:)
      @bookshelf = bookshelf
      @viewer = viewer
      @filter = filter
    end

    def call
      relation = @bookshelf.fictions
      return [relation, 0, nil] unless hide_on_this_shelf?

      filtered = @filter.apply(relation)
      [filtered, relation.count - filtered.count, @filter.fingerprint]
    end

    private

    def hide_on_this_shelf?
      @filter.active? && @bookshelf.user_id != @viewer&.id
    end
  end
end
