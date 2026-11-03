# frozen_string_literal: true

require 'test_helper'

module Contests
  class ParticipationsControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers
    include CoverUploadHelper
    include ContestFictionHelper

    setup do
      @contest = contests(:submissions)
      @user = users(:user_one_one_zero)
      @user.scanlator_users.delete_all
      sign_in @user
      @fiction = create_eligible_fiction
    end

    test 'new shows ai and rules only' do
      with_contests_listed do
        get new_contest_participation_path(@contest, fiction_id: @fiction.slug)

        assert_response :success
        assert_select 'input[name="participation[ai_usage]"]', minimum: 3
        assert_select 'input[name="fiction[title]"]', count: 0
      end
    end

    test 'unlisted participation is hidden from non-admins' do
      get new_contest_participation_path(@contest, fiction_id: @fiction.slug)

      assert_response :not_found
    end

    test 'create accepts an existing fiction' do
      with_contests_listed do
        assert_difference -> { ContestEntry.count } => 1 do
          post contest_participation_path(@contest, fiction_id: @fiction.slug), params: {
            participation: { ai_usage: 'assist', ai_note: 'редагування', rules_accepted: '1' }
          }
        end

        assert_redirected_to contest_path(@contest, anchor: 'my-entry')
      end
    end

    test 'destroy withdraws the entry' do
      with_contests_listed do
        entry = ContestEntry.create!(
          contest: @contest,
          fiction: @fiction,
          submitter: @user,
          status: :accepted,
          ai_usage: :none,
          rules_accepted_at: Time.current,
          submitted_at: Time.current
        )

        assert_difference -> { ContestEntry.where(status: :withdrawn).count } => 1 do
          delete contest_participation_path(@contest)
        end

        assert_redirected_to contest_path(@contest)
        assert_predicate entry.reload, :withdrawn?
      end
    end

    private

    def create_eligible_fiction
      create_contest_author_fiction(user: @user, title: 'Уже початий',
                                    created_at: @contest.submissions_open_at + 1.hour)
    end
  end
end
