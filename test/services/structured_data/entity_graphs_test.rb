# frozen_string_literal: true

require 'test_helper'

module StructuredData
  class EntityGraphsTest < ActiveSupport::TestCase
    test 'fiction_book_json includes book metadata' do
      fiction = fictions(:one)
      payload = JSON.parse(
        EntityGraphs.new(asset_url: ->(attachment) { "https://example.test/#{attachment.blob.id}" })
                    .fiction_book_json(fiction)
      )

      assert_equal 'Book', payload['@type']
      assert_equal fiction.title, payload['name']
      assert_equal fiction.author, payload['author']['name']
    end

    test 'site_identity_json includes website graph' do
      payload = JSON.parse(
        EntityGraphs.new(asset_url: ->(_attachment) { 'https://example.test/cover.webp' }).site_identity_json
      )

      assert_equal 'https://schema.org', payload['@context']
      assert_equal 'WebSite', payload['@graph'].first['@type']
    end
  end
end
