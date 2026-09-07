# frozen_string_literal: true

require 'test_helper'

module Catalog
  class RefreshChapterStatsTest < ActiveSupport::TestCase
    setup do
      @fiction = fictions(:one)
      @fiction.scanlator_ids = @fiction.scanlators.ids
      @user = users(:user_one)
      @scanlator = scanlators(:one)
      @content = 'a' * 500
      @fiction.chapters.destroy_all
    end

    test 'sets chapter_count from distinct floored numbers' do
      create_chapter(number: 1)
      create_chapter(number: 2)
      create_chapter(number: 3.1)
      create_chapter(number: 3.2)

      RefreshChapterStats.call(@fiction)

      assert_equal 3, @fiction.reload.chapter_count
    end

    test 'lowers chapter_count after a chapter is destroyed' do
      create_chapter(number: 1)
      gone = create_chapter(number: 2)
      RefreshChapterStats.call(@fiction)
      gone.destroy

      RefreshChapterStats.call(@fiction)

      assert_equal 1, @fiction.reload.chapter_count
    end

    test 'sets last_chapter_at to the latest public time' do
      older = create_chapter(number: 1)
      newer = create_chapter(number: 2)
      older.update_columns(created_at: 2.days.ago, published_at: 2.days.ago) # rubocop:disable Rails/SkipsModelValidations
      newer.update_columns(created_at: 1.hour.ago, published_at: 1.hour.ago) # rubocop:disable Rails/SkipsModelValidations

      RefreshChapterStats.call(@fiction)

      assert_in_delta 1.hour.ago, @fiction.reload.last_chapter_at, 2.seconds
    end

    test 'zeros chapter_count when no chapters remain' do
      create_chapter(number: 1)
      RefreshChapterStats.call(@fiction)
      @fiction.chapters.destroy_all

      RefreshChapterStats.call(@fiction)

      assert_equal 0, @fiction.reload.chapter_count
    end

    test 'clears last_chapter_at when no chapters remain' do
      create_chapter(number: 1)
      RefreshChapterStats.call(@fiction)
      @fiction.chapters.destroy_all

      RefreshChapterStats.call(@fiction)

      assert_nil @fiction.reload.last_chapter_at
    end

    private

    def create_chapter(number:)
      @fiction.chapters.create!(
        title: "Chapter #{number}",
        number:,
        user: @user,
        content: @content,
        scanlator_ids: [@scanlator.id]
      )
    end
  end
end
