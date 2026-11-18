# frozen_string_literal: true

module StructuredData
  # CollectionPage + ItemList + BreadcrumbList JSON-LD for /bookshelves.
  module BookshelvesHubGraph
    include CollectionPageGraph

    def bookshelves_hub_json(entries)
      bookshelves_hub_graph(Array(entries)).to_json
    end

    private

    def bookshelves_hub_graph(entries)
      shelves = unique_hub_shelves(entries)
      page_url = bookshelves_url(only_path: false, **default_public_url_options)
      {
        '@context': 'https://schema.org',
        '@graph': [bookshelves_hub_page(shelves, page_url), bookshelves_hub_breadcrumb(page_url)]
      }
    end

    def bookshelves_hub_page(shelves, page_url)
      collection_page_node(
        name: I18n.t('meta.title.bookshelves.index'),
        description: I18n.t('meta.description.bookshelves.index'),
        url: page_url,
        main_entity: bookshelves_hub_item_list(shelves)
      ).except(:@context)
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

    def bookshelves_hub_breadcrumb(page_url)
      {
        '@type': 'BreadcrumbList',
        '@id': "#{page_url}#breadcrumb",
        itemListElement: [
          { '@type': 'ListItem', position: 1, name: 'Бака', item: public_root_url },
          { '@type': 'ListItem', position: 2, name: I18n.t('bookshelves.index.title'), item: page_url }
        ]
      }
    end
  end
end
