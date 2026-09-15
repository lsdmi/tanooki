# frozen_string_literal: true

require 'test_helper'

module Publications
  class PublicCacheTest < ActiveSupport::TestCase
    test 'bust deletes show and list keys' do
      publication = publications(:tale_approved_one)
      Rails.cache.write(PublicCache.show_key(publication.id), 'show')
      Rails.cache.write(PublicCache.show_key(publication.slug), 'show-slug')
      Rails.cache.write(PublicCache::HIGHLIGHTS_KEY, ['stale'])
      Rails.cache.write(PublicCache::EXCLUDING_HIGHLIGHTS_KEY, ['stale'])
      Rails.cache.write(PublicCache::POPULAR_BLOGS_KEY, ['stale'])
      Rails.cache.write(PublicCache::TOP_TALE_KEY, publication.id)

      PublicCache.bust(publication)

      assert_nil Rails.cache.read(PublicCache.show_key(publication.id))
      assert_nil Rails.cache.read(PublicCache::HIGHLIGHTS_KEY)
      assert_nil Rails.cache.read(PublicCache::TOP_TALE_KEY)
    end

    test 'bust deletes previous slug key after title change' do
      publication = publications(:tale_approved_one)
      old_slug = publication.slug
      Rails.cache.write(PublicCache.show_key(old_slug), 'old')
      publication.update!(title: 'A renamed published blog title')

      PublicCache.bust(publication)

      assert_nil Rails.cache.read(PublicCache.show_key(old_slug))
    end
  end
end
