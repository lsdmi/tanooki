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

    test 'sets chapter_count from distinct number and volume pairs' do
      create_chapter(number: 1)
      create_chapter(number: 2)
      create_chapter(number: 3.1)
      create_chapter(number: 3.2)

      RefreshChapterStats.call(@fiction)

      assert_equal 4, @fiction.reload.chapter_count
    end

    test 'lowers chapter_count after a chapter is destroyed' do
      create_chapter(number: 1)
      gone = create_chapter(number: 2)
      RefreshChapterStats.call(@fiction)
      gone.destroy

      RefreshChapterStats.call(@fiction)

      assert_equal 1, @fiction.reload.chapter_count
    end

    test 'sets last_chapter_at to the latest already-public time' do
      travel_to(2.days.ago) { create_chapter(number: 1) }
      travel_to(1.hour.ago) { create_chapter(number: 2) }

      RefreshChapterStats.call(@fiction)

      assert_in_delta 1.hour.ago, @fiction.reload.last_chapter_at, 2.seconds
    end

    test 'ignores scheduled published_at when setting last_chapter_at' do
      travel_to(3.days.ago) { create_chapter(number: 1) }
      create_chapter(number: 2, published_at: 2.days.from_now)

      RefreshChapterStats.call(@fiction)

      assert_in_delta 3.days.ago, @fiction.reload.last_chapter_at, 2.seconds
      assert_equal 2, @fiction.chapter_count
    end

    test 'clears last_chapter_at when every remaining chapter is still scheduled' do
      create_chapter(number: 1, published_at: 1.day.from_now)

      RefreshChapterStats.call(@fiction)

      assert_equal 1, @fiction.reload.chapter_count
      assert_nil @fiction.last_chapter_at
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

    test 'writes projections even when the fiction would fail validations' do
      create_chapter(number: 1)
      @fiction.scanlator_ids = []

      RefreshChapterStats.call(@fiction)

      assert_equal 1, @fiction.chapter_count
      assert_equal 1, @fiction.reload.chapter_count
    end

    test 'does not bump updated_at' do
      create_chapter(number: 1)
      before = @fiction.reload.updated_at

      RefreshChapterStats.call(@fiction)

      assert_equal before, @fiction.reload.updated_at
    end

    private

    def create_chapter(number:, published_at: nil)
      @fiction.chapters.create!(
        title: "Chapter #{number}",
        number:,
        published_at:,
        user: @user,
        content: @content,
        scanlator_ids: [@scanlator.id]
      )
    end
  end
end
