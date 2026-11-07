# frozen_string_literal: true

require 'test_helper'

module Contests
  class ShowPresenterTest < ActiveSupport::TestCase
    setup do
      @reader = users(:user_two)
      @admin = users(:user_one)
    end

    def presenter(contest, user = nil)
      ShowPresenter.new(contest: contests(contest), user:)
    end

    test 'role is guest without a user' do
      assert_equal :guest, presenter(:submissions).role
    end

    test 'role is reader for a signed-in user without an entry' do
      assert_equal :reader, presenter(:submissions, @reader).role
    end

    test 'role is admin for admins even with an entry' do
      assert_equal :admin, presenter(:submissions, @admin).role
    end

    test 'role is participant with an accepted or rejected entry' do
      contest_entries(:accepted).update!(submitter_id: @reader.id)

      assert_equal :participant, presenter(:submissions, @reader).role

      contest_entries(:accepted).update!(status: :withdrawn)
      contest_entries(:rejected).update!(submitter_id: @reader.id)

      assert_equal :participant, presenter(:submissions, @reader).role
      assert_equal contest_entries(:rejected), presenter(:submissions, @reader).my_entry
    end

    test 'withdrawn entry does not make a participant' do
      contest_entries(:withdrawn).update!(submitter_id: @reader.id)

      assert_equal :reader, presenter(:submissions, @reader).role
      assert_nil presenter(:submissions, @reader).my_entry
    end

    test 'guest primary action in announced phase reads the rules' do
      assert_equal({ label_key: 'contests.show.actions.read_rules', label_args: {}, href: '#rules', kind: :anchor },
                   presenter(:announced).primary_action)
    end

    test 'guest primary action in submissions phase goes through sign in' do
      expected_join = Rails.application.routes.url_helpers.new_user_session_path(
        return_to: new_fiction_path_for('submissions-contest')
      )

      assert_equal expected_join, presenter(:submissions).primary_action[:href]
    end

    test 'guest primary action after submissions jumps to a section' do
      { judging: '#works', results: '#results', cancelled: '#cancelled' }.each do |phase, href|
        assert_equal href, presenter(phase).primary_action[:href]
      end
    end

    test 'announced secondary action is telegram' do
      secondary = presenter(:announced).secondary_action

      assert_equal :external, secondary[:kind]
      assert_equal ApplicationController.helpers.telegram_site_url, secondary[:href]
    end

    test 'participant primary action points to my entry' do
      contest_entries(:accepted).update!(submitter_id: @reader.id)
      subject = presenter(:submissions, @reader)

      assert_equal '#my-entry', subject.primary_action[:href]
      assert_includes subject.secondary_action[:href], '/chapters/new'
    end

    test 'admin actions link to admin pages' do
      submissions = presenter(:submissions, @admin).primary_action

      assert_equal Rails.application.routes.url_helpers.admin_contest_entries_path(contests(:submissions)),
                   submissions[:href]
      assert_equal 'contests.show.actions.review_entries', submissions[:label_key]
    end

    test 'admin announced action links to the edit page' do
      assert_equal Rails.application.routes.url_helpers.edit_admin_contest_path(contests(:announced)),
                   presenter(:announced, @admin).primary_action[:href]
    end

    test 'admin has no primary action for cancelled contests' do
      assert_nil presenter(:cancelled, @admin).primary_action
    end

    test 'admin has no payout button on a finished contest' do
      assert_nil presenter(:results, @admin).primary_action
    end

    private

    def new_fiction_path_for(slug)
      Rails.application.routes.url_helpers.new_fiction_path(contest: slug)
    end
  end
end
