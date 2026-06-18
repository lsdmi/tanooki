# frozen_string_literal: true

require 'test_helper'

module WeeklyDigests
  class StatsTest < ActiveSupport::TestCase
    include WeeklyDigestFixtureHelpers

    setup do
      @wednesday = Time.zone.parse('2026-05-07 14:00')
    end

    test 'counts chapters published this week' do
      travel_to @wednesday do
        seed_weekly_digest_fixture_data!

        stats = Stats.build(now: @wednesday)

        assert_equal 2, stats.chapters_this_week_count
      end
    end

    test 'selects top chapter from last week by views' do
      travel_to @wednesday do
        seed_weekly_digest_fixture_data!

        stats = Stats.build(now: @wednesday)

        assert_equal chapters(:two), stats.top_chapter
      end
    end

    test 'selects top fiction by reading activity last week' do
      travel_to @wednesday do
        seed_weekly_digest_fixture_data!

        stats = Stats.build(now: @wednesday)

        assert_equal fictions(:two), stats.top_fiction
      end
    end

    test 'selects a featured fiction with a chapter last week' do
      travel_to @wednesday do
        seed_weekly_digest_fixture_data!

        stats = Stats.build(now: @wednesday)

        assert_equal fictions(:one), stats.featured_fiction
      end
    end
  end
end
