# frozen_string_literal: true

module Bookshelves
  # Hub index relation: shelves with enough works after the viewer's filter.
  class HubScope
    MIN_FICTIONS = 3

    def self.relation(filter:, viewer: nil)
      new(filter:, viewer:).relation
    end

    def self.ids_with_at_least(minimum = MIN_FICTIONS)
      BookshelfFiction.group(:bookshelf_id)
                      .having('COUNT(*) >= ?', minimum)
                      .select(:bookshelf_id)
    end

    def initialize(filter:, viewer: nil)
      @filter = filter
      @viewer = viewer
    end

    def relation
      sized = Bookshelf.where(id: self.class.ids_with_at_least)
      return sized unless @filter&.active?

      visible = Bookshelf.where(id: ids_with_visible_at_least)
      return visible unless @viewer

      # Owner still sees their own sized shelves when the filter hides most works.
      visible.or(sized.where(user_id: @viewer.id))
    end

    private

    def ids_with_visible_at_least
      BookshelfFiction.where(fiction_id: @filter.apply(Fiction.all).select(:id))
                      .group(:bookshelf_id)
                      .having('COUNT(*) >= ?', MIN_FICTIONS)
                      .select(:bookshelf_id)
    end
  end
end
