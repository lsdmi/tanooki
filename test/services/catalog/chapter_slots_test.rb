# frozen_string_literal: true

require 'test_helper'

module Catalog
  class ChapterSlotsTest < ActiveSupport::TestCase
    setup do
      @fiction = fictions(:one)
      @fiction.scanlator_ids = @fiction.scanlators.ids
      @user = users(:user_one)
      @scanlator = scanlators(:one)
      @content = 'a' * 500
      @fiction.chapters.destroy_all
    end

    test 'counts decimal chapter numbers separately so 1, 2, 3.1, 3.2 is four slots' do
      create_chapter(number: 1)
      create_chapter(number: 2)
      create_chapter(number: 3.1)
      create_chapter(number: 3.2)

      assert_equal 4, ChapterSlots.call(@fiction)
    end

    test 'counts duplicate translations of the same number once' do
      create_chapter(number: 1)
      create_chapter(number: 1)

      assert_equal 1, ChapterSlots.call(@fiction)
    end

    test 'counts duplicate translations of the same decimal number once' do
      create_chapter(number: 3.1)
      create_chapter(number: 3.1)

      assert_equal 1, ChapterSlots.call(@fiction)
    end

    test 'counts the same number in two volumes as two slots' do
      create_chapter(number: 1, volume_number: 1)
      create_chapter(number: 1, volume_number: 2)

      assert_equal 2, ChapterSlots.call(@fiction)
    end

    test 'returns zero when the listing has no chapters' do
      assert_equal 0, ChapterSlots.call(@fiction)
    end

    test 'excludes soft-deleted chapters' do
      create_chapter(number: 1)
      create_chapter(number: 2).destroy

      assert_equal 1, ChapterSlots.call(@fiction.reload)
    end

    test 'includes scheduled chapters' do
      create_chapter(number: 1, published_at: 1.day.from_now)

      assert_equal 1, ChapterSlots.call(@fiction)
    end

    private

    def create_chapter(number:, volume_number: nil, published_at: nil)
      @fiction.chapters.create!(
        title: "Chapter #{number}",
        number:,
        volume_number:,
        published_at:,
        user: @user,
        content: @content,
        scanlator_ids: [@scanlator.id]
      )
    end
  end
end
