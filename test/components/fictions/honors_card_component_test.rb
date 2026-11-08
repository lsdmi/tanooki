# frozen_string_literal: true

require 'test_helper'

module Fictions
  class HonorsCardComponentTest < ViewComponentTestCase
    test 'shows the contest badge for a top-five place' do
      fiction = fictions(:one)
      entry = contest_entries(:qualified)
      prize = ContestPrize.create!(
        contest: entry.contest, position: 8, title: '2 місце', kind: :place, place: 2, cash_uah: 0
      )
      ContestAward.create!(
        contest: entry.contest, contest_prize: prize, contest_entry: entry, awarded_at: Time.current
      )
      entry.contest.update!(slug: 'original')

      Contests::PublicAccess.stub(:public_show_slugs, %w[original]) do
        render_inline(HonorsCardComponent.new(ranks: {}, fiction:, user: users(:user_one)))
      end

      assert_selector 'a[href="/contests/original"] img[src*="badges/thumbs/original"]'
      assert_selector 'span', text: '#2'
      assert_text entry.contest.title
    end

    test 'shows the contest badge to guests while an archive show is public' do
      fiction = fictions(:one)
      entry = contest_entries(:qualified)
      prize = ContestPrize.create!(
        contest: entry.contest, position: 8, title: '2 місце', kind: :place, place: 2, cash_uah: 0
      )
      ContestAward.create!(
        contest: entry.contest, contest_prize: prize, contest_entry: entry, awarded_at: Time.current
      )
      entry.contest.update!(slug: 'original')

      Contests::PublicAccess.stub(:public_show_slugs, %w[original]) do
        render_inline(HonorsCardComponent.new(ranks: {}, fiction:, user: nil))
      end

      assert_selector 'a[href="/contests/original"] img[src*="badges/thumbs/original"]'
    end
  end
end
