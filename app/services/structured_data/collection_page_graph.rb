# frozen_string_literal: true

module StructuredData
  # Shared CollectionPage JSON-LD node for catalog-style surfaces.
  module CollectionPageGraph
    private

    def collection_page_node(name:, description:, url:, main_entity:, author: nil)
      {
        '@context': 'https://schema.org',
        '@type': 'CollectionPage',
        name:,
        description:,
        url:,
        isPartOf: { '@type': 'WebSite', name: 'Бака', url: public_root_url },
        author:,
        mainEntity: main_entity
      }.compact
    end
  end
end
