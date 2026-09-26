# frozen_string_literal: true

require 'test_helper'

module Library
  class ContinueReadingPresenterTest < ActiveSupport::TestCase
    setup do
      @user = users(:user_one)
      @reading = reading_progresses(:one)
      @first = chapters(:one)
      @latest = chapters(:two)
      ReadingChapterRead.where(user: @user).delete_all
    end

    test 'engaged mid-book continues at the resume chapter' do
      presenter = presenter_for(resume: @first)

      assert_not presenter.all_read?
      assert_equal @first, presenter.continue_chapter
      assert_equal 0, presenter.read_count
    end

    test 'completed mid-book continues at the following chapter' do
      mark_read(@first)
      presenter = presenter_for(resume: @first)

      assert_not presenter.all_read?
      assert_equal @latest, presenter.continue_chapter
      assert_equal 1, presenter.read_count
    end

    test 'accidental open of the latest chapter is not all read' do
      presenter = presenter_for(resume: @latest)

      assert_not presenter.all_read?
      assert_equal @latest, presenter.continue_chapter
    end

    test 'latest chapter actually completed is all read' do
      mark_read(@latest)

      assert_predicate presenter_for(resume: @latest), :all_read?
    end

    test 'counts sparse reads, not the resume position' do
      mark_read(@latest)
      presenter = presenter_for(resume: @first)

      assert_equal [1, 2], [presenter.read_count, presenter.total]
      assert_equal @first, presenter.continue_chapter
    end

    test 'another translation of the latest chapter counts as all read' do
      other_team = Chapter.create!(fiction: @latest.fiction, user: @user, title: 'Other team', number: @latest.number,
                                   content: 'x' * 500, scanlator_ids: [scanlators(:two).id])
      mark_read(other_team)

      assert_predicate presenter_for(resume: @first), :all_read?
    end

    test 'pre-rebuild row counts through its old pointer and continues past it' do
      @reading.update!(legacy_read_through_chapter_id: @first.id)
      presenter = presenter_for(resume: @first)

      assert_equal 1, presenter.read_count
      assert_equal @latest, presenter.continue_chapter
    end

    test 'pre-rebuild row with the pointer on the latest chapter stays all read' do
      @reading.update!(legacy_read_through_chapter_id: @latest.id)

      assert_predicate presenter_for(resume: @latest), :all_read?
    end

    test 'resumes inside the chapter only when continuing at the resume chapter itself' do
      assert_predicate presenter_for(resume: @first), :resume?

      mark_read(@first)

      assert_not presenter_for(resume: @first).resume?
    end

    test 'fiction marked finished is all read with a full count' do
      @reading.update!(chapter: @first, status: :finished)
      presenter = continue_reading

      assert_predicate presenter, :all_read?
      assert_equal presenter.total, presenter.read_count
    end

    private

    def presenter_for(resume:)
      @reading.update!(chapter: resume, status: :active)
      continue_reading
    end

    def continue_reading
      ContinueReadingPresenter.new(@reading.reload, viewer: @user)
    end

    def mark_read(chapter)
      ReadingChapterRead.create!(user: @user, fiction: chapter.fiction, chapter:,
                                 completed_at: Time.current, source: 'scroll')
    end
  end
end
