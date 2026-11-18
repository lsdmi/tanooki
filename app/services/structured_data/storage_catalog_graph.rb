# frozen_string_literal: true

module StructuredData
  # CollectionPage + ItemList JSON-LD for /fictions/alphabetical (current page only).
  module StorageCatalogGraph
    include CollectionPageGraph

    def storage_catalog_json(fictions)
      storage_catalog_graph(Array(fictions)).to_json
    end

    private

    def storage_catalog_graph(fictions)
      collection_page_node(
        name: I18n.t('meta.title.fiction_lists.alphabetical'),
        description: I18n.t('meta.description.fiction_lists.alphabetical'),
        url: alphabetical_fictions_url(only_path: false, **default_public_url_options),
        main_entity: storage_catalog_item_list(fictions)
      )
    end

    def storage_catalog_item_list(fictions)
      {
        '@type': 'ItemList',
        numberOfItems: fictions.size,
        itemListElement: storage_catalog_list_items(fictions)
      }
    end

    def storage_catalog_list_items(fictions)
      fictions.each_with_index.map do |fiction, index|
        {
          '@type': 'ListItem',
          position: index + 1,
          url: fiction_url(fiction, only_path: false, **default_public_url_options),
          name: fiction.title
        }
      end
    end
  end
end
