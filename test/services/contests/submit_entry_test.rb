# frozen_string_literal: true

require 'test_helper'

module Contests
  class SubmitEntryTest < ActiveSupport::TestCase
    setup do
      @contest = contests(:submissions)
      @user = users(:user_one)
      @fiction = fictions(:one)
      @fiction.contest_entries.delete_all
      FictionGenre.find_or_create_by!(fiction: @fiction, genre_id: genres(:original).id)
      @fiction.update!(created_at: @contest.submissions_open_at + 1.hour)
    end

    test 'creates accepted entry with nil reviewed_at' do
      entry = submit_with_ai_note.entry

      assert_predicate entry, :accepted?
      assert_nil entry.reviewed_at
      assert_predicate entry.rules_accepted_at, :present?
    end

    test 'stores ai answers and links the author' do
      entry = submit_with_ai_note.entry

      assert_equal 'assist', entry.ai_usage
      assert_equal 'для правопису', entry.ai_note
      assert entry.authors.exists?(id: @user.id)
    end

    test 'reopens rejected entry as accepted' do
      entry = create_rejected_entry
      result = resubmit

      assert_equal entry.id, result.entry.id
      assert_predicate entry.reload, :accepted?
    end

    test 'reopened entry clears review fields' do
      entry = create_rejected_entry
      resubmit

      assert_nil entry.reload.reviewed_at
      assert_nil entry.status_reason
    end

    test 'unique index blocks duplicate race' do
      SubmitEntry.call(
        user: @user,
        contest: @contest,
        fiction: @fiction,
        ai_usage: 'none',
        rules_accepted: true
      )

      assert_raises(ActiveRecord::RecordNotUnique, SubmitEntry::Error, ActiveRecord::RecordInvalid) do
        ContestEntry.create!(
          contest: @contest,
          fiction: @fiction,
          submitter: @user,
          status: :accepted,
          ai_usage: :none,
          submitted_at: Time.current,
          rules_accepted_at: Time.current
        )
      end
    end

    private

    def submit_with_ai_note
      SubmitEntry.call(
        user: @user,
        contest: @contest,
        fiction: @fiction,
        ai_usage: 'assist',
        ai_note: 'для правопису',
        rules_accepted: true
      )
    end

    def create_rejected_entry
      ago = 1.day.ago
      ContestEntry.create!(
        contest: @contest, fiction: @fiction, submitter: @user,
        status: :rejected, status_reason: 'тема', ai_usage: :none,
        submitted_at: ago, reviewed_at: ago, reviewed_by: @user, rules_accepted_at: ago
      )
    end

    def resubmit
      SubmitEntry.call(user: @user, contest: @contest, fiction: @fiction, ai_usage: 'none', rules_accepted: true)
    end
  end
end
