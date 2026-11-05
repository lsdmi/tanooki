# frozen_string_literal: true

require 'test_helper'

module Admin
  class ContestsControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers
    include ReadyContestHelper

    setup do
      @admin = users(:user_one)
      sign_in @admin
      @contest = contests(:draft)
    end

    test 'reader is sent home' do
      sign_in users(:user_two)
      get admin_contests_url

      assert_redirected_to root_path
    end

    test 'admin sees contest list' do
      get admin_contests_url

      assert_response :success
      assert_select 'h1', text: I18n.t('admin.contests.title')
      assert_select 'a', text: @contest.title
    end

    test 'admin creates a contest with prizes' do
      assert_difference -> { Contest.count } => 1, -> { ContestPrize.count } => 1 do
        post_new_contest
      end

      assert_redirected_to admin_contest_path(Contest.order(:id).last)
    end

    test 'created contest keeps title and prize' do
      post_new_contest
      contest = Contest.order(:id).last

      assert_equal 'Новий конкурс адміна', contest.title
      assert_equal 1, contest.prizes.count
    end

    test 'publish without readiness is blocked' do
      post publish_admin_contest_url(@contest)

      assert_redirected_to admin_contest_path(@contest)
      assert_match(/Ще не готово/, flash[:alert])
    end

    test 'publish without readiness keeps contest unpublished' do
      post publish_admin_contest_url(@contest)

      assert_nil @contest.reload.published_at
    end

    test 'publish sets published_at and rules_snapshot when ready' do
      contest = prepare_ready_contest!

      post publish_admin_contest_url(contest)

      assert_redirected_to admin_contest_path(contest)
      contest.reload

      assert_predicate contest.published_at, :present?
      assert_predicate contest.rules_snapshot, :present?
    end

    test 'cancel without reason is rejected' do
      post cancel_admin_contest_url(@contest), params: { cancel_reason: '' }

      assert_redirected_to admin_contest_path(@contest)
      assert_nil @contest.reload.cancelled_at
    end

    test 'cancel with reason sets cancelled_at' do
      post cancel_admin_contest_url(@contest), params: { cancel_reason: 'Замало учасників' }

      assert_redirected_to admin_contest_path(@contest)
      assert_predicate @contest.reload.cancelled_at, :present?
      assert_equal 'Замало учасників', @contest.cancel_reason
    end

    test 'publish_results sets results_published_at and touches winner fiction' do
      contest = contests(:judging)
      prize = ContestPrize.create!(contest:, title: '1 місце', kind: :place, place: 1, position: 0)
      entry = contest_entries(:qualified)
      ContestAward.create!(contest:, contest_prize: prize, contest_entry: entry, awarded_at: Time.current)
      fiction = entry.fiction
      before = fiction.updated_at

      travel 1.second do
        post publish_results_admin_contest_url(contest)
      end

      assert_redirected_to admin_contest_path(contest)
      assert_predicate contest.reload.results_published_at, :present?
      assert_operator fiction.reload.updated_at, :>, before
    end

    private

    def post_new_contest
      post admin_contests_url, params: { contest: new_contest_params }
    end

    def new_contest_params
      open_at = 1.month.from_now.change(sec: 0)
      {
        title: 'Новий конкурс адміна',
        kind: 'original',
        announced_at: 1.week.from_now,
        submissions_open_at: open_at,
        submissions_close_at: open_at + 10.weeks,
        judging_close_at: open_at + 13.weeks
      }.merge(new_contest_rules)
    end

    def new_contest_rules
      {
        jury_weight: 60,
        max_content_rating: 18,
        max_entries_per_user: 1,
        prize_pool_uah: 3000,
        prizes_attributes: { '0' => { title: '1 місце', kind: 'place', place: 1, position: 0, cash_uah: 1500 } }
      }
    end
  end

  class ContestsShowTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      sign_in users(:user_one)
    end

    test 'show warns about unreviewed entries after the deadline' do
      contest = contests(:judging)
      contest_entries(:qualified).update!(reviewed_at: nil)

      get admin_contest_url(contest)

      assert_response :success
      assert_select 'p', text: /неперевірені заявки/
      assert_select 'a', text: I18n.t('admin.contests.entries.link')
    end
  end
end
