# frozen_string_literal: true

require 'test_helper'

module Admin
  module Contests
    class AwardsControllerTest < ActionDispatch::IntegrationTest
      include Devise::Test::IntegrationHelpers

      setup do
        @admin = users(:user_one)
        sign_in @admin
        @contest = contests(:results)
        @prize = contest_prizes(:first_place)
        @entry = contest_entries(:legacy_winner)
      end

      test 'assigns prize to entry' do
        contest = contests(:judging)
        prize = ContestPrize.create!(contest:, title: 'Дебют', kind: :nomination, position: 0)
        entry = contest_entries(:qualified)

        assert_difference -> { ContestAward.count }, 1 do
          post admin_contest_awards_url(contest), params: {
            contest_prize_id: prize.id,
            contest_entry_id: entry.id
          }
        end

        assert_redirected_to admin_contest_path(contest)
      end

      test 'marks award paid with note' do
        award = contest_awards(:legacy_first)

        patch admin_contest_award_url(@contest, award), params: {
          contest_award: { payout_note: 'На картку', mark_paid: '1' }
        }

        assert_redirected_to admin_contest_path(@contest)
        award.reload

        assert_predicate award.paid_at, :present?
        assert_equal 'На картку', award.payout_note
      end
    end
  end
end
