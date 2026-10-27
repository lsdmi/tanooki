# frozen_string_literal: true

require 'test_helper'

module Catalog
  class RefreshChapterStatsPauseTest < ActiveSupport::TestCase
    setup do
      @fiction = fictions(:one)
      @fiction.scanlator_ids = @fiction.scanlators.ids
      @user = users(:user_one)
      @scanlator = scanlators(:one)
      @fiction.chapters.destroy_all
    end

    test 'a newer public chapter clears a pause and leaves completed_at' do
      travel_to(10.days.ago) { create_chapter(number: 1) }
      RefreshChapterStats.call(@fiction)
      completed_at = 3.days.ago.change(usec: 0)
      @fiction.update!(paused_at: 1.day.ago, completed_at:)
      create_chapter(number: 2)

      RefreshChapterStats.call(@fiction)
      @fiction.reload

      assert_nil @fiction.paused_at
      assert_in_delta completed_at, @fiction.completed_at, 1.second
    end

    test 'refreshing an older public chapter leaves the pause and completed_at' do
      travel_to(10.days.ago) { create_chapter(number: 1) }
      RefreshChapterStats.call(@fiction)
      completed_at = 3.days.ago.change(usec: 0)
      paused_at = 1.day.ago.change(usec: 0)
      @fiction.update!(paused_at:, completed_at:)
      @fiction.chapters.sole.update!(title: 'Retitled', scanlator_ids: [@scanlator.id])

      RefreshChapterStats.call(@fiction)
      @fiction.reload

      assert_in_delta paused_at, @fiction.paused_at, 1.second
      assert_in_delta completed_at, @fiction.completed_at, 1.second
    end

    test 'no public chapters left clears a pause' do
      create_chapter(number: 1)
      RefreshChapterStats.call(@fiction)
      @fiction.update!(paused_at: 1.day.ago)
      @fiction.chapters.destroy_all

      RefreshChapterStats.call(@fiction)

      assert_nil @fiction.reload.paused_at
    end

    private

    def create_chapter(number:)
      @fiction.chapters.create!(
        title: "Chapter #{number}",
        number:,
        user: @user,
        content: 'a' * 500,
        scanlator_ids: [@scanlator.id]
      )
    end
  end
end
