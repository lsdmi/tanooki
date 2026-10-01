# frozen_string_literal: true

require 'test_helper'

class FictionsControllerShowReadCtaTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  CTA = '#fiction-hero-actions a[data-turbo-preload="true"][href*="/chapters/"]'
  SHELVES = '#fiction-hero-actions [role="dialog"] form'

  setup do
    sign_in users(:user_one)
    @fiction = fictions(:one)
    @first = chapters(:one)
    @latest = chapters(:two)
    @progress = reading_progresses(:one)
    ReadingChapterRead.where(user: users(:user_one)).delete_all
  end

  test 'without a resume cursor the CTA reads from the first chapter and prefetches it once' do
    @progress.destroy!
    get fiction_url(@fiction)

    assert_select 'a[data-turbo-preload="true"][href*="/chapters/"]', count: 1
    assert_select "#{CTA}[href=?] span", chapter_path(@first), text: 'Читати · Розділ 1'
  end

  test 'mid-chapter cursor continues there with the restore flag and names the chapter' do
    @progress.update!(chapter: @latest, status: :active, resume_at: 1.hour.ago)
    get fiction_url(@fiction)

    assert_select "#{CTA}[href=?] span", chapter_path(@latest, resume: 1), text: 'Продовжити · Розділ 2'
  end

  test 'a shelf without any chapter opened still reads from the first chapter, with no progress line' do
    @progress.update!(chapter: @first, status: :active, resume_at: nil)
    get fiction_url(@fiction)

    assert_select "#{CTA}[href=?] span", chapter_path(@first), text: 'Читати · Розділ 1'
    assert_select '#fiction-hero-actions p', text: /прочитано/, count: 0
  end

  test 'a finished resume chapter continues at the next one without restoring' do
    mark_read(@first)
    @progress.update!(chapter: @first, status: :active)
    get fiction_url(@fiction)

    assert_select "#{CTA}[href=?] span", chapter_path(@latest), text: 'Продовжити · Розділ 2'
  end

  test 'everything read offers reading again from the first chapter' do
    mark_read(@latest)
    @progress.update!(chapter: @latest, status: :active)
    get fiction_url(@fiction)

    assert_select "#{CTA}[href=?] span", chapter_path(@first), text: 'Читати знову'
  end

  test 'progress line counts read chapters and when the reader was last here' do
    mark_read(@first)
    @progress.update!(chapter: @latest, status: :active, resume_at: 2.days.ago)
    get fiction_url(@fiction)

    assert_select '#fiction-hero-actions p', text: '1 з 2 прочитано · востаннє 2 дні тому'
  end

  test 'progress line without a chapter visit time leaves the time out' do
    mark_read(@first)
    @progress.update!(chapter: @latest, status: :active, resume_at: nil)
    get fiction_url(@fiction)

    assert_select '#fiction-hero-actions p', text: '1 з 2 прочитано'
  end

  test 'no progress line without a reading progress' do
    @progress.destroy!
    get fiction_url(@fiction)

    assert_select '#fiction-hero-actions p', text: /прочитано/, count: 0
  end

  test 'without a shelf the picker adds to any shelf and offers no removal' do
    @progress.destroy!
    get fiction_url(@fiction)

    assert_select '#fiction-hero-actions button span', text: 'Додати до читальні'
    assert_select "#{SHELVES} [aria-current]", count: 0
    assert_select SHELVES, count: Library::ReadingState::STATUSES.size
  end

  test 'shelf picker shows the current shelf among every shelf' do
    @progress.update!(status: :postponed)
    get fiction_url(@fiction)

    assert_select '#fiction-hero-actions button span', text: 'Читальня: Відкладено'
    assert_select "#{SHELVES} button[aria-current]", text: 'Відкладено', count: 1
    assert_select "#{SHELVES}[action=?] input[name=status][value=finished]",
                  update_status_fiction_reading_progress_path(@fiction)
  end

  test 'shelf picker removes from the library without a confirmation' do
    get fiction_url(@fiction)

    assert_select "#{SHELVES}:not([data-turbo-confirm]) input[name=status][value=destroy]"
  end

  test 'guests read from the first chapter' do
    sign_out :user
    get fiction_url(@fiction)

    assert_select "#{CTA}[href=?] span", chapter_path(@first), text: 'Читати · Розділ 1'
    assert_select '#fiction-hero-actions [data-guest-continue-read-label-value=?]', 'Читати · Розділ 1'
  end

  test 'guests add to the library through sign-in' do
    sign_out :user
    get fiction_url(@fiction)

    assert_select '#fiction-hero-actions a[href=?]', new_user_session_path(return_to: fiction_path(@fiction)),
                  text: 'Додати до читальні'
    assert_select SHELVES, count: 0
  end

  private

  def mark_read(chapter)
    ReadingChapterRead.create!(user: users(:user_one), fiction: chapter.fiction, chapter:,
                               completed_at: Time.current, source: 'scroll')
  end
end
