# frozen_string_literal: true

require 'test_helper'

class FictionShowPresenterTest < ActiveSupport::TestCase
  setup do
    @fiction = fictions(:one)
    @user = users(:user_one)
    @presenter = FictionShowPresenter.new(@fiction, @user, {})
  end

  test 'ordered chapter relations are memoized' do
    asc = @presenter.send(:ordered_chapters)
    desc = @presenter.send(:ordered_chapters_desc)

    assert_same asc, @presenter.send(:ordered_chapters)
    assert_same desc, @presenter.send(:ordered_chapters_desc)
  end

  test 'default tab is About for guests' do
    assert_equal :about, FictionShowPresenter.new(@fiction, nil, {}).default_tab
  end

  test 'default tab is About when the fiction is shelved but no chapter was opened or read' do
    reading_progresses(:one).update!(resume_at: nil)
    ReadingChapterRead.where(user: @user).delete_all

    assert_equal :about, @presenter.default_tab
  end

  test 'default tab is Chapters once the reader opened a chapter' do
    reading_progresses(:one).update!(resume_at: 1.hour.ago)

    assert_equal :chapters, @presenter.default_tab
  end

  test 'first and last chapter use memoized ordered relations' do
    assert_equal chapters(:one), @presenter.first_chapter
    assert_equal chapters(:two), @presenter.send(:last_chapter)
    assert_same @presenter.send(:ordered_chapters), @presenter.instance_variable_get(:@ordered_chapters)
  end
end
