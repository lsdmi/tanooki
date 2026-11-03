# frozen_string_literal: true

require 'test_helper'

module Contests
  class SubmissionFormTest < ActiveSupport::TestCase
    include CoverUploadHelper
    include ContestFictionHelper

    setup do
      @contest = contests(:submissions)
      @user = users(:user_one_one_zero)
      @user.scanlator_users.delete_all
    end

    test 'creates author page fiction and accepted entry in one go' do
      form = new_work_form

      assert_difference -> { Fiction.count } => 1,
                        -> { ContestEntry.count } => 1,
                        -> { Scanlator.count } => 1 do
        saved = form.save

        assert_empty form.errors.full_messages
        assert saved
      end
    end

    test 'created fiction has a cover and the contest genre' do
      form = new_work_form
      form.save

      assert_predicate form.fiction.cover, :attached?
      assert_includes form.fiction.genres, genres(:original)
    end

    test 'created entry is accepted and owned by the author page' do
      form = new_work_form
      form.save

      assert_predicate form.entry, :accepted?
      assert_includes @user.reload.scanlators, form.scanlator
    end

    test 'rolls back everything when entry step fails' do
      ContestJuror.create!(contest: @contest, user: @user, role: :member)

      form = SubmissionForm.new(
        user: @user,
        contest: @contest,
        params: {
          title: 'Не пройде',
          description: 'Короткий опис твору для конкурсу з достатньою довжиною тексту.',
          ai_usage: 'none',
          rules_accepted: true
        }
      )

      assert_no_difference %w[Fiction.count ContestEntry.count Scanlator.count] do
        assert_not form.save
      end
    end

    test 'existing_fiction returns newest eligible work' do
      older = create_user_fiction(title: 'Старе демо', created_at: 1.day.ago)
      newer = create_user_fiction(title: 'Нове демо', created_at: 1.hour.ago)

      form = SubmissionForm.new(user: @user, contest: @contest, params: {})

      assert_equal newer, form.existing_fiction
      assert_not_equal older, form.existing_fiction
    end

    test 'rejects unconfirmed email with an actionable message' do
      @user.update!(confirmed_at: nil)
      form = SubmissionForm.new(
        user: @user,
        contest: @contest,
        params: {
          title: 'Без пошти',
          description: 'Короткий опис твору для конкурсу з достатньою довжиною тексту.',
          content_rating: 'everyone',
          ai_usage: 'none',
          rules_accepted: true
        }
      )

      assert_not form.save
      assert_includes form.errors[:base].join, 'Підтвердь пошту'
    end

    test 'requires an explicit ai_usage choice' do
      form = SubmissionForm.new(
        user: @user,
        contest: @contest,
        params: {
          title: 'Без ШІ-відповіді',
          description: 'Короткий опис твору для конкурсу з достатньою довжиною тексту.',
          content_rating: 'everyone',
          rules_accepted: true
        }
      )

      assert_not form.save
      assert_predicate form.errors[:ai_usage], :any?
    end

    private

    def new_work_form
      SubmissionForm.new(user: @user, contest: @contest, params: new_work_params)
    end

    def new_work_params
      {
        title: 'Новий поріг',
        description: ContestFictionHelper::CONTEST_FICTION_DESCRIPTION,
        content_rating: 0,
        ai_usage: 'none',
        rules_accepted: true
      }
    end

    def create_user_fiction(title:, created_at:)
      create_contest_author_fiction(user: @user, title:, created_at:)
    end
  end
end
