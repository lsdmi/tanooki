# frozen_string_literal: true

module StructuredData
  # View entry point for entity JSON-LD graphs; delegates to StructuredData::EntityGraphs.
  module JsonLdEntitiesHelper
    def site_identity_meta
      entity_graphs.site_identity_json
    end

    def fiction_book_meta(fiction)
      entity_graphs.fiction_book_json(fiction)
    end

    def about_page_meta
      entity_graphs.about_page_json
    end

    def chapter_article_meta(chapter)
      entity_graphs.chapter_article_json(chapter)
    end

    private

    def entity_graphs
      @entity_graphs ||= StructuredData::EntityGraphs.new(asset_url: method(:url_for))
    end
  end
end
