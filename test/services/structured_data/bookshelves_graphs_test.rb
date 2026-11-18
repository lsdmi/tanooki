# frozen_string_literal: true

require 'test_helper'

module StructuredData
  class BookshelvesGraphsTest < ActiveSupport::TestCase
    setup do
      @graphs = EntityGraphs.new(asset_url: ->(attachment) { "https://example.test/#{attachment.blob.id}" })
    end

    test 'bookshelves_hub_json lists shelves as a CollectionPage ItemList' do
      entry = Bookshelves::HubPreview::Entry.new(
        bookshelf: bookshelves(:one), covers: [], fictions_count: 2, top_genres: [], max_content_rating: 0
      )
      payload = JSON.parse(@graphs.bookshelves_hub_json([entry]))

      assert_equal 'CollectionPage', payload['@type']
      assert_equal 'ItemList', payload.dig('mainEntity', '@type')
      assert_equal bookshelves(:one).title, payload.dig('mainEntity', 'itemListElement', 0, 'name')
    end

    test 'bookshelf_show_json lists fictions as a CollectionPage ItemList' do
      bookshelf = bookshelves(:one)
      payload = JSON.parse(@graphs.bookshelf_show_json(bookshelf, [fictions(:one)]))

      assert_equal 'CollectionPage', payload['@type']
      assert_equal bookshelf.title, payload['name']
      assert_equal 'ItemList', payload.dig('mainEntity', '@type')
    end
  end
end
