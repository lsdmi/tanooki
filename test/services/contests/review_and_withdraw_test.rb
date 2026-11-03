# frozen_string_literal: true

require 'test_helper'

module Contests
  class ReviewAndWithdrawTest < ActiveSupport::TestCase
    setup do
      @admin = users(:user_one)
      @entry = contest_entries(:accepted)
    end

    test 'reject requires reason and sets rejected' do
      ReviewEntry.call(entry: @entry, actor: @admin, action: :reject, reason: 'Не та тема')

      assert_predicate @entry.reload, :rejected?
      assert_equal 'Не та тема', @entry.status_reason
    end

    test 'reject records the reviewer' do
      ReviewEntry.call(entry: @entry, actor: @admin, action: :reject, reason: 'Не та тема')

      assert_predicate @entry.reload.reviewed_at, :present?
      assert_equal @admin, @entry.reviewed_by
    end

    test 'mark_reviewed is not a moderation action' do
      assert_raises(ReviewEntry::Error) do
        ReviewEntry.call(entry: @entry, actor: @admin, action: :mark_reviewed)
      end
    end

    test 'disqualify requires reason' do
      assert_raises(ReviewEntry::Error) do
        ReviewEntry.call(entry: @entry, actor: @admin, action: :disqualify, reason: '')
      end
    end

    test 'author can withdraw before results' do
      WithdrawEntry.call(entry: @entry, actor: @admin)

      assert_predicate @entry.reload, :withdrawn?
    end

    test 'cannot withdraw after results' do
      entry = contest_entries(:legacy_winner)

      assert_raises(WithdrawEntry::Error) do
        WithdrawEntry.call(entry:, actor: @admin)
      end
    end

    test 'admin may moderate entries' do
      assert_predicate Authorization.new(@admin, @entry), :moderate?
      assert_not Authorization.new(users(:user_two), @entry).moderate?
    end
  end
end
