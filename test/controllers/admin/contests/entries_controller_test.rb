# frozen_string_literal: true

require 'test_helper'

module Admin
  module Contests
    class EntriesControllerTest < ActionDispatch::IntegrationTest
      include Devise::Test::IntegrationHelpers

      setup do
        @admin = users(:user_one)
        sign_in @admin
        @contest = contests(:submissions)
        @entry = contest_entries(:accepted)
      end

      test 'reader is sent home' do
        sign_in users(:user_two)
        get admin_contest_entries_url(@contest)

        assert_redirected_to root_path
      end

      test 'lists entries' do
        get admin_contest_entries_url(@contest)

        assert_response :success
        assert_select 'li', text: /#{@entry.display_title}/
      end

      test 'lists entries without an approval queue' do
        get admin_contest_entries_url(@contest)

        assert_select 'a', text: /Не перевірено/, count: 0
        assert_select 'form button, form input[type=submit]', text: /Перевірено/, count: 0
      end

      test 'reject with reason' do
        patch admin_contest_entry_url(@contest, @entry),
              params: { moderation: 'reject', reason: 'Не та тема' }

        assert_redirected_to admin_contest_entries_path(@contest)
        assert_predicate @entry.reload, :rejected?
        assert_equal 'Не та тема', @entry.status_reason
      end

      test 'disqualify with reason' do
        patch admin_contest_entry_url(@contest, @entry),
              params: { moderation: 'disqualify', reason: 'Плагіат' }

        assert_redirected_to admin_contest_entries_path(@contest)
        assert_predicate @entry.reload, :disqualified?
      end

      test 'shows private ai_note to admin' do
        @entry.update!(ai_note: 'використовував для правопису')
        get admin_contest_entries_url(@contest)

        assert_response :success
        assert_select 'li', text: /використовував для правопису/
      end
    end
  end
end
