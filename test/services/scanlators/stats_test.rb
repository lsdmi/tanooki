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
      stale_time = 90.days.ago
      scanlator.chapters.find_each do |chapter|
        # rubocop:disable Rails/SkipsModelValidations -- activity window depends on historical timestamps
        chapter.update_columns(published_at: stale_time, created_at: stale_time)
        # rubocop:enable Rails/SkipsModelValidations
      end

      assert_not Stats.compute(scanlator).active_recently?
    end

    test 'reports active when a chapter was released within the activity window' do
      scanlator = scanlators(:one)
      stale_time = 90.days.ago
      scanlator.chapters.find_each do |chapter|
        # rubocop:disable Rails/SkipsModelValidations -- activity window depends on historical timestamps
        chapter.update_columns(published_at: stale_time, created_at: stale_time)
        # rubocop:enable Rails/SkipsModelValidations
      end
      # rubocop:disable Rails/SkipsModelValidations -- activity window depends on historical timestamps
      scanlator.chapters.first.update_columns(published_at: 1.day.ago, created_at: 1.day.ago)
      # rubocop:enable Rails/SkipsModelValidations

      assert_predicate Stats.compute(scanlator), :active_recently?
    end
  end
end
