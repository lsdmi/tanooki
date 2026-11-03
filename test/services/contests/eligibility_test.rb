# frozen_string_literal: true

require 'test_helper'

module Contests
  class EligibilityTest < ActiveSupport::TestCase
    setup do
      @contest = contests(:submissions)
      @user = users(:user_one)
      @fiction = fictions(:one)
      # fiction :one already has an accepted entry — use a fresh fiction link for happy path
      @fiction.contest_entries.delete_all
      FictionGenre.find_or_create_by!(fiction: @fiction, genre_id: genres(:original).id)
    end

    test 'allows confirmed manager during submissions' do
      eligibility = Eligibility.new(user: @user, contest: @contest, fiction: @fiction)

      assert_predicate eligibility, :allowed?
      assert_empty eligibility.reasons
    end

    test 'wrong_phase outside submissions' do
      eligibility = Eligibility.new(user: @user, contest: contests(:announced), fiction: @fiction)

      assert_not eligibility.allowed?
      assert_includes eligibility.reasons, :wrong_phase
    end

    test 'email_unconfirmed' do
      @user.update!(confirmed_at: nil)
      eligibility = Eligibility.new(user: @user, contest: @contest, fiction: @fiction)

      assert_not eligibility.allowed?
      assert_includes eligibility.reasons, :email_unconfirmed
    end

    test 'juror_or_organizer' do
      eligibility = Eligibility.new(user: users(:user_two), contest: @contest, fiction: @fiction)

      assert_not eligibility.allowed?
      assert_includes eligibility.reasons, :juror_or_organizer
    end

    test 'entry_limit_reached' do
      contest_entries(:rejected).update!(
        status: :accepted,
        status_reason: nil,
        reviewed_at: nil,
        reviewed_by_id: nil
      )
      eligibility = Eligibility.new(user: @user, contest: @contest, fiction: @fiction)

      assert_not eligibility.allowed?
      assert_includes eligibility.reasons, :entry_limit_reached
    end

    test 'requires_new_work' do
      @fiction.update!(created_at: @contest.submissions_open_at - 1.day)
      eligibility = Eligibility.new(user: @user, contest: @contest, fiction: @fiction)

      assert_not eligibility.allowed?
      assert_includes eligibility.reasons, :requires_new_work
    end

    test 'missing_required_genre' do
      @fiction.fiction_genres.where(genre_id: genres(:original).id).delete_all
      eligibility = Eligibility.new(user: @user, contest: @contest, fiction: @fiction)

      assert_not eligibility.allowed?
      assert_includes eligibility.reasons, :missing_required_genre
    end

    test 'content_rating_too_high' do
      @contest.update!(max_content_rating: 0)
      @fiction.update!(content_rating: :eighteen)
      eligibility = Eligibility.new(user: @user, contest: @contest, fiction: @fiction)

      assert_not eligibility.allowed?
      assert_includes eligibility.reasons, :content_rating_too_high
    end

    test 'already_entered' do
      ContestEntry.create!(
        contest: @contest,
        fiction: @fiction,
        submitter: @user,
        status: :accepted,
        ai_usage: :none,
        submitted_at: Time.current,
        rules_accepted_at: Time.current
      )
      eligibility = Eligibility.new(user: @user, contest: @contest, fiction: @fiction)

      assert_not eligibility.allowed?
      assert_includes eligibility.reasons, :already_entered
    end

    test 'does_not_manage_fiction' do
      stranger = users(:user_one_one_zero)
      eligibility = Eligibility.new(user: stranger, contest: @contest, fiction: @fiction)

      assert_not eligibility.allowed?
      assert_includes eligibility.reasons, :does_not_manage_fiction
    end

    test 'reason messages are human and actionable' do
      @user.update!(confirmed_at: nil)
      messages = Eligibility.new(user: @user, contest: @contest).reason_messages

      assert(messages.any? { |msg| msg.include?('Підтвердь пошту') })
    end
  end
end
