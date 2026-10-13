# frozen_string_literal: true

require 'test_helper'

module Scanlators
  class StatsTest < ActiveSupport::TestCase
    test 'computes chapter counts and views' do
      stats = Stats.compute(scanlators(:one))

      assert_equal 2, stats.chapters_count
      assert_equal 0, stats.total_views
    end

    test 'computes rating aggregates' do
      stats = Stats.compute(scanlators(:one))

      assert_in_delta 4.5, stats.average_rating
      assert_equal 2, stats.total_rating_count
    end

    test 'reports inactive when no recent chapter releases' do
      scanlator = scanlators(:one)
      backdate_scanlator_chapters!(scanlator, 90.days.ago)

      assert_not Stats.compute(scanlator).active_recently?
    end

    test 'reports active when a chapter was released within the activity window' do
      scanlator = scanlators(:one)
      backdate_scanlator_chapters!(scanlator, 90.days.ago)
      release_chapter_at!(scanlator.chapters.first, 1.day.ago)

      assert_predicate Stats.compute(scanlator), :active_recently?
    end

    test 'excludes drafts from chapter counts and views' do
      scanlator = scanlators(:one)
      draft = scanlator.chapters.first
      draft.update!(status: :draft, scanlator_ids: draft.scanlators.ids, views: 50)

      stats = Stats.compute(scanlator)

      assert_equal 1, stats.chapters_count
      assert_equal 0, stats.total_views
    end

    test 'counts thanks on non-draft chapters' do
      chapter = scanlators(:one).chapters.not_draft.first
      ChapterThank.create!(user: users(:user_two), chapter:)

      assert_equal 1, Stats.compute(scanlators(:one)).total_thanks_count
    end

    test 'old cache hashes without thanks still load as zero' do
      stats = Stats.from_h(
        chapters_count: 1, total_views: 2, active_recently: true,
        average_rating: 4.0, total_rating_count: 1
      )

      assert_equal 0, stats.total_thanks_count
    end

    private

    def backdate_scanlator_chapters!(scanlator, time)
      scanlator.chapters.find_each do |chapter|
        release_chapter_at!(chapter, time)
      end
    end

    def release_chapter_at!(chapter, time)
      travel_to time do
        chapter.update!(published_at: Time.current, scanlator_ids: chapter.scanlators.ids)
      end
    end
  end
end
