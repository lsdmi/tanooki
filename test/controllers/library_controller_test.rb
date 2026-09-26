# frozen_string_literal: true

require 'test_helper'

class LibraryControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:user_two)
    sign_in @user
  end

  test 'should get index' do
    get library_url

    assert_response :success
  end

  test 'should fetch history with related associations' do
    get library_url

    assert_response :success
    assert_library_history_preloaded(assigns(:history))
  end

  test 'library prefetches only the first continue reading CTA' do
    sign_in users(:user_one)
    ReadingChapterRead.where(user: users(:user_one)).delete_all
    reading_progresses(:one).update!(status: :active, chapter: chapters(:one))
    reading_progresses(:two).update!(status: :postponed)

    get library_url(section: :active)

    assert_response :success
    assert_select 'a[data-turbo-preload="true"][href*="/chapters/"]', count: 1
    assert_select 'span', text: 'Читати далі'
  end

  test 'accidental latest open still offers continue reading at that chapter' do
    sign_in users(:user_one)
    ReadingChapterRead.where(user: users(:user_one)).delete_all
    reading_progresses(:one).update!(status: :active, chapter: chapters(:two))

    get library_url(section: :active)

    assert_select "#reading-progress-#{reading_progresses(:one).id} a[href=?]", chapter_path(chapters(:two), resume: 1)
    assert_select "#reading-progress-#{reading_progresses(:one).id}", text: /Все прочитано/, count: 0
  end

  test 'completed latest chapter shows all read with the sparse count' do
    sign_in users(:user_one)
    reading_progresses(:one).update!(status: :active, chapter: chapters(:two))

    get library_url(section: :active)

    card = "#reading-progress-#{reading_progresses(:one).id}"

    assert_select card, text: /Все прочитано/
    assert_select "#{card} span.font-bold", text: '1'
  end

  test 'should not change status for invalid status param' do
    sign_in users(:user_one)
    reading_progress = reading_progresses(:one)
    reading_progress.update!(status: :active)

    patch update_reading_progress_path(reading_progress), params: { status: :invalid, current_section: :active }

    assert_response :success
    assert_equal 'active', reading_progress.reload.status
    assert_includes response.body, I18n.t('reading_progress.alerts.invalid_status')
  end

  private

  def assert_library_history_preloaded(history)
    assert_not_nil history
    assert_kind_of ActiveRecord::Relation, history

    history.each { |reading| assert_reading_graph_loaded(reading) }
  end

  def assert_reading_graph_loaded(reading)
    assert_not_nil reading.fiction
    assert_not_nil reading.chapter

    assert_not_nil reading.fiction.cover_attachment
    assert_not_nil reading.fiction.cover_attachment.blob

    assert_not_nil reading.fiction.genres
  end
end
