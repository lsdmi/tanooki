# frozen_string_literal: true

require 'test_helper'
require_relative 'merge_fixture'

module Fictions
  class MergeDryRunTest < ActiveSupport::TestCase
    include MergeFixture

    REPORT = <<~TEXT.chomp
      chapters 1
      reading_chapter_reads 1
      reading_progresses moved 1 kept_newer 1 removed 1
      fiction_ratings moved 1 kept_newer 1 removed 1
      bookshelf_fictions moved 1 skipped 1
      fiction_genres moved 1 skipped 1
      fiction_scanlators moved 1 skipped 1
      comments 1
      views 4
      titles english_title ukrainian_title
    TEXT

    setup do
      @admin = users(:user_one)
      @source = build_fiction('merge-source', 'Джерело')
      @target = build_fiction('merge-target', 'Ціль')
      @chapter = build_chapter(@source, 'merge-source-ch', 1)
    end

    test 'dry run prints row counts and writes nothing' do
      seed_report_rows
      Rails.cache.write(IndexVariablesManager::POPULAR_NOVELTY_IDS_CACHE_KEY, [7])

      report = with_dry_run { Merge.call(source: @source, target: @target, admin: @admin) }

      assert_equal REPORT, report
      assert_equal @source.id, @chapter.reload.fiction_id
      assert_equal [7], Rails.cache.read(IndexVariablesManager::POPULAR_NOVELTY_IDS_CACHE_KEY)
    end

    private

    def seed_report_rows
      @source.views = 4
      @source.english_title = 'Source English'
      @source.save!(validate: false)
      seed_reader_rows
      seed_catalog_rows
    end

    def seed_reader_rows
      build_read
      build_progress(@source, users(:user_one), @chapter, updated_at: Time.current)
      seed_shared_progress
      seed_ratings
      Comment.create!(user: users(:user_one), commentable: @source, content: 'Нотатка до твору')
    end

    def seed_shared_progress
      target_chapter = build_chapter(@target, 'merge-target-ch', 2)
      build_progress(@target, users(:user_two), target_chapter, updated_at: 2.days.ago)
      build_progress(@source, users(:user_two), @chapter, updated_at: 1.hour.ago)
    end

    def seed_ratings
      FictionRating.create!(user: users(:user_one), fiction: @source, rating: 4)
      FictionRating.create!(user: users(:user_two), fiction: @target, rating: 2).update!(updated_at: 1.hour.ago)
      FictionRating.create!(user: users(:user_two), fiction: @source, rating: 5).update!(updated_at: 2.days.ago)
    end

    def seed_catalog_rows
      seed_shelves
      seed_genres
      seed_scanlators
    end

    def seed_shelves
      BookshelfFiction.create!(bookshelf: bookshelves(:one), fiction: @target)
      BookshelfFiction.create!(bookshelf: bookshelves(:one), fiction: @source)
      BookshelfFiction.create!(bookshelf: bookshelves(:two), fiction: @source)
    end

    def seed_genres
      FictionGenre.create!(fiction: @target, genre: genres(:one))
      FictionGenre.create!(fiction: @source, genre: genres(:one))
      FictionGenre.create!(fiction: @source, genre: genres(:two))
    end

    def seed_scanlators
      shared = build_scanlator('merge-team-shared')
      only = build_scanlator('merge-team-only')
      FictionScanlator.create!(fiction: @source, scanlator: shared)
      FictionScanlator.create!(fiction: @target, scanlator: shared)
      FictionScanlator.create!(fiction: @source, scanlator: only)
    end

    def with_dry_run
      previous = ENV.fetch('DRY_RUN', nil)
      ENV['DRY_RUN'] = '1'
      yield
    ensure
      previous.nil? ? ENV.delete('DRY_RUN') : ENV['DRY_RUN'] = previous
    end
  end
end
