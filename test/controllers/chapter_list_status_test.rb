# frozen_string_literal: true

require 'test_helper'

class ChapterListStatusTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  WASH = '.bg-stone-50'
  LABELS = '[data-chapter-drawer-search-labels-value]'

  setup do
    @user = users(:user_one)
    @fiction = fictions(:one)
    ReadingChapterRead.where(user: @user).delete_all
    reading_progresses(:one).update!(chapter: chapters(:two), status: :active)
    ReadingChapterRead.create!(user: @user, fiction: @fiction, chapter: chapters(:one),
                               completed_at: Time.current, source: 'scroll')
  end

  test 'the drawer washes read rows only and marks where the reader stopped' do
    sign_in @user
    unread = Chapter.create!(fiction: @fiction, user: @user, title: 'Chapter 3', number: 3, content: 'x' * 500,
                             scanlator_ids: [scanlators(:one).id])
    get chapter_url(unread)
    in_progress = drawer_row(chapters(:two), :in_progress)

    assert_select "#{drawer_row(chapters(:one), :read)} > div#{WASH}"
    assert_select "#{in_progress} span.sr-only", text: I18n.t('chapters.reader_chapter_drawer.progress_in_progress')
    assert_select "#{in_progress} #{WASH}, #{drawer_row(unread, :current)} #{WASH}", count: 0
  end

  test 'the signed-in fiction page tints the same rows as the drawer' do
    sign_in @user
    get fiction_url(@fiction)

    assert_select "li[data-chapter-status=read] > div#{WASH} span[role=img][aria-label=?]",
                  I18n.t('chapters.reader_chapter_drawer.progress_read')
    assert_select 'li[data-chapter-status=in_progress] span[role=img][aria-label=?]',
                  I18n.t('chapters.reader_chapter_drawer.progress_in_progress')
  end

  test 'lazy fiction page sections carry the same statuses' do
    sign_in @user
    get chapter_section_fiction_path(@fiction, section: 'r-1-100', order: 'asc')

    assert_equal %w[read in_progress], css_select('li[data-chapter-status]').pluck('data-chapter-status')
  end

  test 'guests get plain fiction page rows' do
    get fiction_url(@fiction)

    assert_select '#chapters-list li[data-chapter-status], #chapters-list li span[role=img]', count: 0
  end

  test 'drawer search results get status labels for screen readers' do
    sign_in @user
    get chapter_url(chapters(:one))
    labels = JSON.parse(css_select(LABELS).first['data-chapter-drawer-search-labels-value'])

    assert_equal I18n.t('chapters.reader_chapter_drawer.progress_in_progress'), labels['in_progress']
  end

  private

  def drawer_row(chapter, status)
    "li#reader_drawer_chapter_#{chapter.id}[data-chapter-status=#{status}]"
  end
end
