# frozen_string_literal: true

require 'test_helper'

module Contests
  class PlaceBadgesTest < ActiveSupport::TestCase
    test 'returns a top-five place when the contest has badge artwork' do
      entry = contest_entries(:qualified)
      prize = ContestPrize.create!(
        contest: entry.contest, position: 8, title: '2 місце', kind: :place, place: 2, cash_uah: 0
      )
      ContestAward.create!(
        contest: entry.contest, contest_prize: prize, contest_entry: entry, awarded_at: Time.current
      )

      badges = PlaceBadges.stub(:asset?, true) { PlaceBadges.new(fictions(:one)).call }

      assert_equal [2], badges.map(&:place)
      assert_equal entry.contest.slug, badges.first.slug
      assert_includes badges.first.href, '/contests/judging-contest'
    end

    test 'skips places outside the top five and contests without artwork' do
      entry = contest_entries(:qualified)
      prize = ContestPrize.create!(
        contest: entry.contest, position: 8, title: '6 місце', kind: :place, place: 6, cash_uah: 0
      )
      ContestAward.create!(
        contest: entry.contest, contest_prize: prize, contest_entry: entry, awarded_at: Time.current
      )

      assert_empty PlaceBadges.stub(:asset?, true) { PlaceBadges.new(fictions(:one)).call }
    end
  end
end
