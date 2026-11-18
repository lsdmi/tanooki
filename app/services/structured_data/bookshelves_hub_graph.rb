# frozen_string_literal: true

module StructuredData
  # CollectionPage + ItemList JSON-LD for /bookshelves (focus + current updates page).
  module BookshelvesHubGraph
    include CollectionPageGraph

    def bookshelves_hub_json(entries)
      bookshelves_hub_graph(Array(entries)).to_json
    end

    private

    def bookshelves_hub_graph(entries)
      shelves = unique_hub_shelves(entries)
      collection_page_node(
        name: I18n.t('meta.title.bookshelves.index'),
        description: I18n.t('meta.description.bookshelves.index'),
        url: bookshelves_url(only_path: false, **default_public_url_options),
        main_entity: bookshelves_hub_item_list(shelves)
      )
    end

    def unique_hub_shelves(entries)
      entries.map(&:bookshelf).uniq(&:id)
    end

    def bookshelves_hub_item_list(shelves)
      {
        '@type': 'ItemList',
        numberOfItems: shelves.size,
        itemListElement: shelves.each_with_index.map { |shelf, index| bookshelves_hub_list_item(shelf, index) }
      }
    end

    def bookshelves_hub_list_item(shelf, index)
      {
        '@type': 'ListItem',
        position: index + 1,
        url: bookshelf_url(shelf, only_path: false, **default_public_url_options),
        name: shelf.title
      }
    end
  end
end
