# frozen_string_literal: true

module Fictions
  # Public curated bookshelves that include a fiction — inbound links for fiction About.
  class CuratedBookshelves
    LIMIT = 8
    MIN_FICTIONS = Bookshelves::HubScope::MIN_FICTIONS

    def self.call(fiction:, viewer: nil, filter: ContentFilters::Preference.open)
      new(fiction:, viewer:, filter:).call
    end

    def initialize(fiction:, viewer: nil, filter: ContentFilters::Preference.open)
      @fiction = fiction
      @viewer = viewer
      @filter = filter
    end

    def call
      @fiction.bookshelves
              .merge(Bookshelves::HubScope.relation(filter: @filter, viewer: @viewer))
              .most_viewed
              .limit(LIMIT)
              .to_a
    end
  end
end
