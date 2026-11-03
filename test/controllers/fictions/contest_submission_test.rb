# frozen_string_literal: true

require 'test_helper'

module Fictions
  class ContestSubmissionTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers
    include CoverUploadHelper
    include ContestFictionHelper

    setup do
      @contest = contests(:submissions)
      @user = users(:user_one_one_zero)
      @user.scanlator_users.delete_all
      sign_in @user
    end

    test 'new contest form opens without a scanlator team' do
      with_contests_listed do
        get new_fiction_path(contest: @contest.slug)

        assert_response :success
        assert_select 'h1', text: /Подаю на конкурс/
        assert_select 'form[action=?]', fictions_path(contest: @contest.slug)
      end
    end

    test 'guest is sent to login with return_to when listed' do
      with_contests_listed do
        sign_out @user

        get new_fiction_path(contest: @contest.slug)

        assert_redirected_to new_user_session_path
        assert_equal new_fiction_path(contest: @contest.slug), session[:user_return_to]
      end
    end

    test 'unlisted contest submit is hidden from non-admins' do
      get new_fiction_path(contest: @contest.slug)

      assert_response :not_found
    end

    test 'create submits and redirects to my participation' do
      with_contests_listed do
        assert_difference -> { ContestEntry.count } => 1 do
          post fictions_path(contest: @contest.slug), params: {
            fiction: {
              title: 'Конкурсний дебют',
              description: 'Опис твору для конкурсу з достатньою довжиною тексту.',
              content_rating: 'everyone',
              ai_usage: 'none',
              rules_accepted: '1'
            }
          }
        end

        assert_redirected_to contest_path(@contest, anchor: 'my-entry')
        follow_redirect!

        assert_select '#my-entry'
      end
    end

    test 'already entered redirects to my participation' do
      with_contests_listed do
        fiction = create_owned_fiction
        ContestEntry.create!(
          contest: @contest,
          fiction:,
          submitter: @user,
          status: :accepted,
          ai_usage: :none,
          rules_accepted_at: Time.current,
          submitted_at: Time.current
        )

        get new_fiction_path(contest: @contest.slug)

        assert_redirected_to contest_path(@contest, anchor: 'my-entry')
      end
    end

    private

    def create_owned_fiction
      create_contest_author_fiction(user: @user, title: 'Уже поданий')
    end
  end
end
