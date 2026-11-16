# frozen_string_literal: true

module Fictions
  # Public curated bookshelves that include a fiction — inbound links for fiction About.
  class CuratedBookshelves
    LIMIT = 8

    def self.call(fiction:)
      new(fiction:).call
    end

    def initialize(fiction:)
      @fiction = fiction
    end

    def call
      @fiction.bookshelves.most_viewed.limit(LIMIT).to_a
    end
  end
end
