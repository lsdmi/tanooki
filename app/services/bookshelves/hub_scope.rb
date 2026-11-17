# frozen_string_literal: true

module Bookshelves
  # Hub index relation: shelves with ≥1 work left after the viewer's filter.
  # Matches show behaviour — the owner's own shelves stay visible.
  class HubScope
    def self.relation(viewer:, filter:)
      new(viewer:, filter:).relation
    end

    def initialize(viewer:, filter:)
      @viewer = viewer
      @filter = filter
    end

    def relation
      return Bookshelf.all unless @filter&.active?

      with_visible = Bookshelf.where(id: bookshelf_ids_with_visible_fiction)
      return with_visible unless @viewer

      with_visible.or(Bookshelf.where(user_id: @viewer.id))
    end

    private

    def bookshelf_ids_with_visible_fiction
      BookshelfFiction.where(fiction_id: @filter.apply(Fiction.all).select(:id)).select(:bookshelf_id)
    end
  end
end
