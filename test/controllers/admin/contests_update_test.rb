# frozen_string_literal: true

require 'test_helper'

module Admin
  class ContestsUpdateTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      sign_in users(:user_one)
      @contest = contests(:submissions)
    end

    test 'published contest saves teaser and theme without a rule-change reason' do
      prize = ContestPrize.create!(
        contest: @contest, title: '1 місце', kind: :place, place: 1, position: 0, cash_uah: 100
      )

      patch admin_contest_url(@contest), params: { contest: unchanged_params.merge(
        teaser_text: 'Новий тизер',
        description: '<p>Нова тема</p>',
        prizes_attributes: { '0' => prize_params(prize) }
      ) }

      assert_redirected_to admin_contest_path(@contest)
      @contest.reload

      assert_equal 'Новий тизер', @contest.teaser_text
      assert_includes @contest.description.to_plain_text, 'Нова тема'
    end

    test 'published contest rejects a rules change without a reason' do
      patch admin_contest_url(@contest), params: { contest: unchanged_params.merge(jury_weight: 80) }

      assert_response :unprocessable_content
      assert_equal 60, @contest.reload.jury_weight
      assert_empty @contest.rule_changes
    end

    test 'published contest records a rules change when a reason is given' do
      patch admin_contest_url(@contest), params: {
        contest: unchanged_params.merge(jury_weight: 80),
        rule_change_reason: 'Змінили вагу журі'
      }

      assert_redirected_to admin_contest_path(@contest)
      @contest.reload

      assert_equal 80, @contest.jury_weight
      assert_equal 1, @contest.rule_changes.size
    end

    test 'juror picker searches users instead of listing everyone' do
      get user_options_admin_contests_url, params: { q: 'John' }, as: :json

      assert_response :success
      assert_includes response.parsed_body.pluck('text'), 'John Doe'
    end

    private

    def unchanged_params
      unchanged_identity.merge(unchanged_schedule).merge(unchanged_rules)
    end

    def unchanged_identity
      { title: @contest.title, kind: @contest.kind, tagline: @contest.tagline }
    end

    def unchanged_schedule
      {
        announced_at: field_time(@contest.announced_at),
        submissions_open_at: field_time(@contest.submissions_open_at),
        submissions_close_at: field_time(@contest.submissions_close_at),
        judging_close_at: field_time(@contest.judging_close_at)
      }
    end

    def unchanged_rules
      {
        requires_new_work: '1', requires_completed: '0',
        min_chapters: @contest.min_chapters, min_words: @contest.min_words, max_words: @contest.max_words.to_s,
        judged_word_cap: @contest.judged_word_cap, judged_chapters_scope: @contest.judged_chapters_scope,
        max_content_rating: @contest.max_content_rating, max_entries_per_user: @contest.max_entries_per_user,
        jury_weight: @contest.jury_weight, prize_pool_uah: @contest.prize_pool_uah,
        donations_uah: @contest.donations_uah, carryover_uah: @contest.carryover_uah
      }
    end

    def prize_params(prize)
      {
        id: prize.id, title: prize.title, kind: prize.kind, place: prize.place,
        position: prize.position, cash_uah: prize.cash_uah, unlock_at_uah: '', perks: ''
      }
    end

    def field_time(time)
      time.strftime('%Y-%m-%dT%H:%M')
    end
  end
end
