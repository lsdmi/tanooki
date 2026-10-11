# frozen_string_literal: true

require 'test_helper'
require_relative 'merge_fixture'

module Fictions
  class MergeListingTest < ActiveSupport::TestCase
    include MergeFixture

    UUID = '9012a7a8-f286-40d2-8f24-374632cf5d6e'

    setup do
      @admin = users(:user_one)
      @source = build_fiction('merge-source', 'Джерело')
      @target = build_fiction('merge-target', 'Ціль')
      @chapter = build_chapter(@source, 'merge-source-ch', 1)
    end

    test 'recomputes chapter stats and adds views' do
      @source.views = 4
      @source.save!(validate: false)
      @target.views = 6
      @target.save!(validate: false)
      build_chapter(@target, 'merge-target-ch', 2, published_at: Time.zone.parse('2026-10-01 12:00'))
      @chapter.published_at = Time.zone.parse('2026-09-01 12:00')
      @chapter.save!(validate: false)

      Merge.call(source: @source, target: @target, admin: @admin)

      target = @target.reload

      assert_equal 2, target.chapter_count
      assert_equal 10, target.views
      assert_in_delta Time.zone.parse('2026-10-01 12:00'), target.last_chapter_at, 1
    end

    test 'keeps the later completion mark' do
      later = Time.zone.parse('2026-10-02 08:00')
      @source.completed_at = Time.zone.parse('2026-09-01 08:00')
      @source.save!(validate: false)
      @target.completed_at = later
      @target.save!(validate: false)

      Merge.call(source: @source, target: @target, admin: @admin)

      assert_in_delta later, @target.reload.completed_at, 1
    end

    test 'copies completion when only the source is complete' do
      mark = Time.zone.parse('2026-09-01 08:00')
      @source.completed_at = mark
      @source.save!(validate: false)

      Merge.call(source: @source, target: @target, admin: @admin)

      assert_in_delta mark, @target.reload.completed_at, 1
    end

    test 'fills blank english and alternative titles from the source' do
      @source.english_title = 'Source English'
      @source.alternative_title = 'Альт'
      @source.save!(validate: false)

      Merge.call(source: @source, target: @target, admin: @admin)

      target = @target.reload

      assert_equal 'Source English', target.english_title
      assert_equal 'Альт', target.alternative_title
    end

    test 'keeps a different ukrainian title as the alternative' do
      Merge.call(source: @source, target: @target, admin: @admin)

      assert_equal 'Джерело', @target.reload.alternative_title
    end

    test 'keeps an alternative title the target already has' do
      @target.alternative_title = 'Вже є'
      @target.save!(validate: false)
      @source.alternative_title = 'Інше'
      @source.save!(validate: false)

      Merge.call(source: @source, target: @target, admin: @admin)

      assert_equal 'Вже є', @target.reload.alternative_title
    end

    test 'expires the fiction index caches' do
      latest = IndexVariablesManager::LATEST_UPDATES_IDS_CACHE_KEY
      reads = ['most_reads_ids', IndexVariablesManager::MOST_READS_INDEX_CARDS]
      Rails.cache.write(IndexVariablesManager::POPULAR_NOVELTY_IDS_CACHE_KEY, [1])
      Rails.cache.write(latest, [1])
      Rails.cache.write(reads, [1])

      Merge.call(source: @source, target: @target, admin: @admin)

      assert_nil Rails.cache.read(IndexVariablesManager::POPULAR_NOVELTY_IDS_CACHE_KEY)
      assert_nil Rails.cache.read(latest)
      assert_nil Rails.cache.read(reads)
    end

    test 'reindexes the surviving fiction when search is enabled' do
      reindexed = false
      @target.define_singleton_method(:reindex) { reindexed = true }

      SearchkickCallbacks.stub(:mode, :inline) do
        Merge.call(source: @source, target: @target, admin: @admin)
      end

      assert reindexed
    end

    test 'claims a free clean slug on the surviving fiction' do
      target = fictions(:one)
      target.slug = "clean-title-#{UUID}"
      target.save!(validate: false)

      Merge.call(source: @source, target:, admin: @admin)

      assert_equal 'clean-title', target.reload.slug
      assert_equal target, MergedRedirect.new("clean-title-#{UUID}").target
    end
  end
end
