# frozen_string_literal: true

module Bookshelves
  # BookshelfFiction rows a hub card may advertise (same visibility as show).
  class HubVisibleMemberships
    def self.call(shelves, viewer: nil, filter: nil)
      new(shelves, viewer:, filter:).call
    end

    def initialize(shelves, viewer: nil, filter: nil)
      @shelves = Array(shelves)
      @viewer = viewer
      @filter = filter
    end

    def call
      ids = @shelves.map(&:id)
      return BookshelfFiction.none if ids.empty?

      base = BookshelfFiction.where(bookshelf_id: ids)
      return base unless @filter&.active?

      owner_ids = owner_shelf_ids
      other_ids = ids - owner_ids
      return base.where(bookshelf_id: owner_ids) if other_ids.empty?
      return filtered(base, other_ids) if owner_ids.empty?

      filtered(base, other_ids).or(base.where(bookshelf_id: owner_ids))
    end

    private

    def filtered(base, bookshelf_ids)
      base.where(bookshelf_id: bookshelf_ids, fiction_id: visible_fiction_ids)
    end

    def owner_shelf_ids
      return [] unless @viewer

      @shelves.select { |shelf| shelf.user_id == @viewer.id }.map(&:id)
    end

    def visible_fiction_ids
      @visible_fiction_ids ||= @filter.apply(Fiction.all).select(:id)
    end
  end
end
