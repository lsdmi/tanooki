# frozen_string_literal: true

require 'test_helper'
require_relative 'merge_fixture'

module Fictions
  class MergeRowsTest < ActiveSupport::TestCase
    include MergeFixture

    setup do
      @admin = users(:user_one)
      @source = build_fiction('merge-source', 'Джерело')
      @target = build_fiction('merge-target', 'Ціль')
      @chapter = build_chapter(@source, 'merge-source-ch', 1)
    end

    test 'moves chapters without changing their slugs' do
      Merge.call(source: @source, target: @target, admin: @admin)

      assert_equal @target.id, @chapter.reload.fiction_id
      assert_equal 'merge-source-ch', @chapter.slug
    end

    test 'moves chapter reads onto the surviving fiction' do
      read = build_read

      Merge.call(source: @source, target: @target, admin: @admin)

      assert_equal @target.id, read.reload.fiction_id
    end

    test 'moves a reading progress that exists only on the source' do
      progress = build_progress(@source, users(:user_one), @chapter, updated_at: Time.current)

      Merge.call(source: @source, target: @target, admin: @admin)

      assert_equal @target.id, progress.reload.fiction_id
    end

    test 'keeps the reading progress updated last' do
      target_chapter = build_chapter(@target, 'merge-target-ch', 2)
      older = build_progress(@target, users(:user_two), target_chapter, updated_at: 2.days.ago)
      newer = build_progress(@source, users(:user_two), @chapter, updated_at: 1.hour.ago)

      Merge.call(source: @source, target: @target, admin: @admin)

      assert_equal newer.id, ReadingProgress.find_by!(user: users(:user_two), fiction: @target).id
      assert_nil ReadingProgress.find_by(id: older.id)
    end

    test 'drops the older source progress when the target is newer' do
      target_chapter = build_chapter(@target, 'merge-target-ch', 2)
      kept = build_progress(@target, users(:user_two), target_chapter, updated_at: 1.hour.ago)
      dropped = build_progress(@source, users(:user_two), @chapter, updated_at: 2.days.ago)

      Merge.call(source: @source, target: @target, admin: @admin)

      assert_equal kept.id, ReadingProgress.find_by!(user: users(:user_two), fiction: @target).id
      assert_nil ReadingProgress.find_by(id: dropped.id)
    end

    test 'keeps the newer rating and moves a source-only rating' do
      shared = users(:user_two)
      FictionRating.create!(user: shared, fiction: @target, rating: 2).update!(updated_at: 1.hour.ago)
      older = FictionRating.create!(user: shared, fiction: @source, rating: 5)
      older.update!(updated_at: 2.days.ago)
      only = FictionRating.create!(user: users(:user_one), fiction: @source, rating: 4)

      Merge.call(source: @source, target: @target, admin: @admin)

      assert_equal 2, FictionRating.find_by!(user: shared, fiction: @target).rating
      assert_nil FictionRating.find_by(id: older.id)
      assert_equal @target.id, only.reload.fiction_id
    end

    test 'moves shelf rows and skips shelves that already hold the target' do
      shared = bookshelves(:one)
      only = bookshelves(:two)
      BookshelfFiction.create!(bookshelf: shared, fiction: @target)
      BookshelfFiction.create!(bookshelf: shared, fiction: @source)
      BookshelfFiction.create!(bookshelf: only, fiction: @source)

      Merge.call(source: @source, target: @target, admin: @admin)

      assert_equal 1, BookshelfFiction.where(bookshelf: shared, fiction: @target).count
      assert_equal @target.id, BookshelfFiction.find_by!(bookshelf: only).fiction_id
      assert_empty BookshelfFiction.where(fiction: @source)
    end

    test 'unions genres without duplicating a shared genre' do
      FictionGenre.create!(fiction: @target, genre: genres(:one))
      FictionGenre.create!(fiction: @source, genre: genres(:one))
      FictionGenre.create!(fiction: @source, genre: genres(:two))
      FictionGenre.create!(fiction: @source, genre: genres(:two))

      Merge.call(source: @source, target: @target, admin: @admin)

      ids = FictionGenre.where(fiction: @target).pluck(:genre_id)

      assert_equal [genres(:one).id, genres(:two).id].sort, ids.sort
      assert_empty FictionGenre.where(fiction: @source)
    end

    test 'unions scanlators, refreshes counters, and drops team stats cache' do
      shared = build_scanlator('merge-team-shared')
      only = build_scanlator('merge-team-only')
      FictionScanlator.create!(fiction: @source, scanlator: shared)
      FictionScanlator.create!(fiction: @target, scanlator: shared)
      FictionScanlator.create!(fiction: @source, scanlator: only)
      Rails.cache.write(Scanlators::ShowPresenter.cache_key_for(only.id), 'stale')

      Merge.call(source: @source, target: @target, admin: @admin)

      assert_equal 1, FictionScanlator.where(scanlator: shared).count
      assert_equal 1, only.reload.fictions_count
      assert_nil Rails.cache.read(Scanlators::ShowPresenter.cache_key_for(only.id))
    end

    test 'moves fiction comments and recounts them' do
      comment = Comment.create!(user: users(:user_one), commentable: @source, content: 'Нотатка до твору')

      Merge.call(source: @source, target: @target, admin: @admin)

      assert_equal @target, comment.reload.commentable
      assert_equal 1, @target.reload.comments_count
      assert_equal 0, Fiction.with_deleted.find(@source.id).comments_count
    end
  end
end
