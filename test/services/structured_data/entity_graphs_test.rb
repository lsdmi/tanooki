# frozen_string_literal: true

require 'test_helper'

module StructuredData
  class EntityGraphsTest < ActiveSupport::TestCase
    setup do
      @graphs = EntityGraphs.new(asset_url: ->(attachment) { "https://example.test/#{attachment.blob.id}" })
    end

    test 'fiction_book_json includes book metadata' do
      fiction = fictions(:one)
      payload = JSON.parse(@graphs.fiction_book_json(fiction))

      assert_equal 'Book', payload['@type']
      assert_equal fiction.title, payload['name']
      assert_equal fiction.author, payload['author']['name']
    end

    test 'fiction_book_json omits contentRating for everyone' do
      payload = JSON.parse(@graphs.fiction_book_json(fictions(:one)))

      assert_not payload.key?('contentRating')
    end

    test 'fiction_book_json includes contentRating for sixteen and eighteen' do
      sixteen = JSON.parse(@graphs.fiction_book_json(fictions(:two)))
      eighteen = JSON.parse(@graphs.fiction_book_json(fictions(:eighteen)))

      assert_equal '16+', sixteen['contentRating']
      assert_equal '18+', eighteen['contentRating']
    end

    test 'site_identity_json includes website graph' do
      payload = JSON.parse(
        EntityGraphs.new(asset_url: ->(_attachment) { 'https://example.test/cover.webp' }).site_identity_json
      )

      assert_equal 'https://schema.org', payload['@context']
      assert_equal 'WebSite', payload['@graph'].first['@type']
    end

    test 'chapter_article_json is blank for drafts' do
      chapter = chapters(:one)
      chapter.status = :draft
      payload = EntityGraphs.new(asset_url: ->(_attachment) { 'https://example.test/cover.webp' })
                            .chapter_article_json(chapter)

      assert_nil payload
    end

    test 'chapter_article_json includes fiction contentRating when labelled' do
      chapter = chapters(:three)
      payload = JSON.parse(@graphs.chapter_article_json(chapter))

      assert_equal 'Article', payload['@type']
      assert_equal '16+', payload['contentRating']
    end

    test 'chapter_article_json omits contentRating for everyone' do
      chapter = chapters(:one)
      payload = JSON.parse(@graphs.chapter_article_json(chapter))

      assert_equal 'Article', payload['@type']
      assert_not payload.key?('contentRating')
    end
  end
end
