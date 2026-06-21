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
    reading_progresses(:one).update!(status: :active, chapter: chapters(:one))
    reading_progresses(:two).update!(status: :postponed)

    get library_url(section: :active)

    assert_response :success
    assert_select 'a[data-turbo-preload="true"][href*="/chapters/"]', count: 1
    assert_select 'span', text: 'Читати далі'
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
