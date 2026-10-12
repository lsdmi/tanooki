# frozen_string_literal: true

require 'test_helper'

module Reading
  class RecentRanobeTest < ActiveSupport::TestCase
    test 'collapses several fresh rows of one fiction into a single place' do
      ReadingProgress.find_each { |progress| stamp(progress, 1.week.ago) }
      stamp(reading_progresses(:one), 1.minute.ago)
      stamp(reading_progresses(:two), 1.hour.ago)
      ReadingProgress.create!(fiction: fictions(:one), user: users(:user_two), chapter: chapters(:one), status: :active)

      assert_equal [fictions(:one), fictions(:two)], RecentRanobe.call
    end

    test 'skips a deleted fiction' do
      ReadingProgress.find_each { |progress| stamp(progress, 1.week.ago) }
      stamp(reading_progresses(:two), Time.current)
      fictions(:two).destroy!

      assert_equal [fictions(:one)], RecentRanobe.call
    end

    private

    def stamp(progress, time)
      travel_to(time) { progress.update!(completed_count: progress.completed_count.to_i + 1) }
    end
  end
end
