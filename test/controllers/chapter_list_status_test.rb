# frozen_string_literal: true

require 'test_helper'

class ChapterListStatusTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  WASH = '.bg-surface'

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

  test 'the signed-in fiction page tints only the continue row and marks read rows with the check' do
    sign_in @user
    get fiction_url(@fiction)

    assert_select 'li[data-chapter-status=read] span[role=img][aria-label=?]',
                  I18n.t('chapters.reader_chapter_drawer.progress_read')
    assert_select "li[data-chapter-status=read] > div#{WASH}", count: 0
    assert_select 'li[data-chapter-status=in_progress] > div.bg-brand-subtle', text: /Продовжити/
  end

  test 'once the resume chapter is read to the end the next chapter is the continue row and stays unread' do
    following = Chapter.create!(fiction: @fiction, user: @user, title: 'Chapter 3', number: 3, content: 'x' * 500,
                                scanlator_ids: [scanlators(:one).id])
    ReadingChapterRead.create!(user: @user, fiction: @fiction, chapter: chapters(:two), completed_at: Time.current,
                               source: 'scroll')
    sign_in @user
    get fiction_url(@fiction)

    assert_select "li#chapter_list_chapter_#{following.id}[data-chapter-status=unread][data-chapter-continue] " \
                  '> div.bg-brand-subtle', text: /Продовжити/
    assert_select 'li[data-chapter-continue]', count: 1
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

  test 'drawer toggles share one kit and the open chapter keeps its marker' do
    sign_in @user
    unread = Chapter.create!(fiction: @fiction, user: @user, title: 'Chapter 3', number: 3, content: 'x' * 500,
                             scanlator_ids: [scanlators(:one).id])
    get chapter_url(unread)

    assert_select '[data-read-toggle-scope] [data-read-toggle-kit]', count: 1
    assert_select "#{drawer_row(unread, :current)} form [data-read-toggle-target=icon] span[aria-label=?]",
                  I18n.t('chapters.reader_chapter_drawer.progress_current')
  end

  test 'the drawer has no row menu' do
    sign_in @user
    get chapter_url(chapters(:one))

    assert_select '[data-row-menu-button], [data-controller~=chapter-row-menu], li[data-read-through]', count: 0
  end

  test 'drawer search results clone labelled status icons from templates' do
    sign_in @user
    get chapter_url(chapters(:one))

    assert_includes response.body, %(data-status="in_progress">)
    %w[read current in_progress].each do |status|
      assert_match(
        /data-status="#{status}"><span[^>]*aria-label="#{I18n.t("chapters.reader_chapter_drawer.progress_#{status}")}"/,
        response.body
      )
    end
    assert_match(/data-status="unread"><span[^>]*aria-hidden="true"/, response.body)
  end

  private

  def drawer_row(chapter, status)
    "li#reader_drawer_chapter_#{chapter.id}[data-chapter-status=#{status}]"
  end
end
