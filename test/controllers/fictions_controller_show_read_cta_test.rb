# frozen_string_literal: true

require 'test_helper'

class FictionsControllerShowReadCtaTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  CTA = 'a[data-turbo-preload="true"][href*="/chapters/"]'

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

    assert_select CTA, count: 1
    assert_select "#{CTA}[href=?] span", chapter_path(@first), text: 'Читати'
    assert_select 'a', text: 'З початку', count: 0
  end

  test 'mid-chapter cursor continues there with the restore flag and offers the start without it' do
    @progress.update!(chapter: @latest, status: :active)
    get fiction_url(@fiction)

    assert_select "#{CTA}[href=?] span", chapter_path(@latest, resume: 1), text: 'Продовжити'
    assert_select 'a:not([data-turbo-preload])[href=?]', chapter_path(@first), text: 'З початку'
  end

  test 'a finished resume chapter continues at the next one without restoring' do
    mark_read(@first)
    @progress.update!(chapter: @first, status: :active)
    get fiction_url(@fiction)

    assert_select "#{CTA}[href=?] span", chapter_path(@latest), text: 'Продовжити'
  end

  test 'everything read falls back to reading from the first chapter' do
    mark_read(@latest)
    @progress.update!(chapter: @latest, status: :active)
    get fiction_url(@fiction)

    assert_select "#{CTA}[href=?] span", chapter_path(@first), text: 'Читати'
    assert_select 'a', text: 'З початку', count: 0
  end

  test 'guests always read from the first chapter' do
    sign_out :user
    get fiction_url(@fiction)

    assert_select "#{CTA}[href=?] span", chapter_path(@first), text: 'Читати'
  end

  private

  def mark_read(chapter)
    ReadingChapterRead.create!(user: users(:user_one), fiction: chapter.fiction, chapter:,
                               completed_at: Time.current, source: 'scroll')
  end
end
