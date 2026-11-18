# frozen_string_literal: true

require 'test_helper'

module StructuredData
  class BookshelvesGraphsTest < ActiveSupport::TestCase
    setup do
      @graphs = EntityGraphs.new(asset_url: ->(attachment) { "https://example.test/#{attachment.blob.id}" })
    end

    test 'bookshelves_hub_json lists shelves as a CollectionPage ItemList with breadcrumbs' do
      entry = Bookshelves::HubPreview::Entry.new(
        bookshelf: bookshelves(:one), covers: [], fictions_count: 2, top_genres: [], max_content_rating: 0
      )
      payload = JSON.parse(@graphs.bookshelves_hub_json([entry]))
      page = payload['@graph'].find { |node| node['@type'] == 'CollectionPage' }
      crumbs = payload['@graph'].find { |node| node['@type'] == 'BreadcrumbList' }

      assert_equal 'ItemList', page.dig('mainEntity', '@type')
      assert_equal bookshelves(:one).title, page.dig('mainEntity', 'itemListElement', 0, 'name')
      assert_equal I18n.t('bookshelves.index.title'), crumbs.dig('itemListElement', 1, 'name')
    end

    test 'bookshelf_show_json lists fictions as a CollectionPage ItemList with breadcrumbs' do
      bookshelf = bookshelves(:one)
      payload = JSON.parse(@graphs.bookshelf_show_json(bookshelf, [fictions(:one)]))
      page = payload['@graph'].find { |node| node['@type'] == 'CollectionPage' }
      crumbs = payload['@graph'].find { |node| node['@type'] == 'BreadcrumbList' }

      assert_equal bookshelf.title, page['name']
      assert_equal 'ItemList', page.dig('mainEntity', '@type')
      assert_equal bookshelf.title, crumbs.dig('itemListElement', 2, 'name')
    end
  end
end
