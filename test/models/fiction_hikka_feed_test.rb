# frozen_string_literal: true

require 'test_helper'

# The cached Hikka list must follow the fields it shows, and only those.
class FictionHikkaFeedTest < ActiveSupport::TestCase
  include MemoryCacheHelper

  setup do
    FakeHikkaLookup.reset!
    @fiction = fictions(:one)
  end

  test 'a new Hikka slug expires the cached list' do
    assert_busted { update_with_lookup(hikka_slug: 'some-novel-1') }
  end

  test 'a changed title, slug or description expires the cached list' do
    { title: 'Нова назва твору', slug: 'novyi-slug', description: 'Новий опис твору, що має достатню довжину.' }
      .each do |attribute, value|
      assert_busted(attribute) { @fiction.update!(attribute => value) }
    end
  end

  test 'a replaced cover expires the cached list' do
    assert_busted do
      @fiction.cover.attach(io: file_fixture('cover_valid.webp').open, filename: 'new-cover.webp')
      @fiction.save!
    end
  end

  test 'deleting the fiction expires the cached list' do
    assert_busted { @fiction.destroy }
  end

  test 'fields the list does not show leave the cache alone' do
    with_memory_cache do
      Fictions::HikkaFeed.fetch
      @fiction.update!(author: 'Інший автор', views: 99)

      assert_not_nil Rails.cache.read(Fictions::HikkaFeed::KEY)
    end
  end

  test 'a rolled-back change leaves the cache alone' do
    with_memory_cache do
      Fictions::HikkaFeed.fetch
      Fiction.transaction do
        @fiction.update!(title: 'Нова назва твору')
        raise ActiveRecord::Rollback
      end

      assert_not_nil Rails.cache.read(Fictions::HikkaFeed::KEY)
    end
  end

  test 'as_hikka_json lists the Hikka slug and the Baka slug, with keys in alphabetical order' do
    @fiction.update_column(:hikka_slug, 'guimi-zhi-zhu-7059fd')

    json = @fiction.as_hikka_json

    assert_equal %i[alternative_title cover_url description english_title hikka_slug reference slug title], json.keys
    assert_equal ['guimi-zhi-zhu-7059fd', @fiction.slug], json.values_at(:hikka_slug, :slug)
    assert_match %r{/fictions/#{@fiction.slug}\z}, json[:reference]
  end

  test 'as_hikka_json gives null for a fiction without a Hikka slug' do
    @fiction.update_column(:hikka_slug, nil)

    assert_nil @fiction.as_hikka_json.fetch(:hikka_slug)
  end

  private

  def update_with_lookup(**attributes)
    Fictions::HikkaLookup.stub(:new, ->(slug) { FakeHikkaLookup.new(slug) }) { @fiction.update!(**attributes) }
  end

  def assert_busted(label = nil)
    with_memory_cache do
      Fictions::HikkaFeed.fetch

      yield

      assert_nil Rails.cache.read(Fictions::HikkaFeed::KEY), label
    end
  end
end
