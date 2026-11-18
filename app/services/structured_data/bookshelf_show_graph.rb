# frozen_string_literal: true

module StructuredData
  # CollectionPage + ItemList JSON-LD for a public bookshelf show (current fiction page).
  module BookshelfShowGraph
    include CollectionPageGraph

    def bookshelf_show_json(bookshelf, fictions)
      bookshelf_show_graph(bookshelf, Array(fictions)).to_json
    end

    private

    def bookshelf_show_graph(bookshelf, fictions)
      collection_page_node(
        name: bookshelf.title,
        description: bookshelf.description,
        url: bookshelf_url(bookshelf, only_path: false, **default_public_url_options),
        author: { '@type': 'Person', name: bookshelf.user_name },
        main_entity: bookshelf_show_item_list(fictions)
      )
    end

    def bookshelf_show_item_list(fictions)
      {
        '@type': 'ItemList',
        numberOfItems: fictions.size,
        itemListElement: fictions.each_with_index.map { |fiction, index| bookshelf_show_list_item(fiction, index) }
      }
    end

    def bookshelf_show_list_item(fiction, index)
      {
        '@type': 'ListItem',
        position: index + 1,
        url: fiction_url(fiction, only_path: false, **default_public_url_options),
        name: fiction.title
      }
    end
  end
end
