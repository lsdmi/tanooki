# frozen_string_literal: true

module StructuredData
  # CollectionPage + ItemList + BreadcrumbList JSON-LD for a public bookshelf show.
  module BookshelfShowGraph
    include CollectionPageGraph

    def bookshelf_show_json(bookshelf, fictions)
      bookshelf_show_graph(bookshelf, Array(fictions)).to_json
    end

    private

    def bookshelf_show_graph(bookshelf, fictions)
      page_url = bookshelf_url(bookshelf, only_path: false, **default_public_url_options)
      hub_url = bookshelves_url(only_path: false, **default_public_url_options)
      {
        '@context': 'https://schema.org',
        '@graph': [
          bookshelf_show_page(bookshelf, fictions, page_url),
          bookshelf_show_breadcrumb(bookshelf, page_url, hub_url)
        ]
      }
    end

    def bookshelf_show_page(bookshelf, fictions, page_url)
      collection_page_node(
        name: bookshelf.title,
        description: bookshelf.description,
        url: page_url,
        author: { '@type': 'Person', name: bookshelf.user_name },
        main_entity: bookshelf_show_item_list(fictions)
      ).except(:@context)
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

    def bookshelf_show_breadcrumb(bookshelf, page_url, hub_url)
      {
        '@type': 'BreadcrumbList',
        '@id': "#{page_url}#breadcrumb",
        itemListElement: [
          { '@type': 'ListItem', position: 1, name: 'Бака', item: public_root_url },
          { '@type': 'ListItem', position: 2, name: I18n.t('bookshelves.index.title'), item: hub_url },
          { '@type': 'ListItem', position: 3, name: bookshelf.title, item: page_url }
        ]
      }
    end
  end
end
