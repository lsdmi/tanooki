# frozen_string_literal: true

require 'test_helper'

class LibraryShelfMenuTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:user_one)
    @reading = reading_progresses(:one)
    @reading.update!(status: :active)
    reading_progresses(:two).update!(status: :active)
  end

  test 'the menu lists the four shelves with the current one checked' do
    get library_url(section: :active)

    menu = "#library-shelf-menu-#{@reading.id}"

    assert_select "#{menu} [aria-current=true]", text: 'Читаю'
    assert_select "#{menu} button[type=submit]", text: /Прочитано|Відкладено|Покинуто/, count: 3
    assert_select "#{menu} form[data-turbo-confirm] button", text: 'Прибрати з читальні'
  end

  test 'moving a row to another shelf drops it from the tab with a toast' do
    move(@reading, :finished)

    assert_equal 'finished', @reading.reload.status
    assert_select 'turbo-stream[action=remove][target=?]', "reading-progress-#{@reading.id}"
    assert_includes response.body, 'Перенесено до «Прочитано»'
  end

  test 'removing a row deletes the reading' do
    move(@reading, :destroy)

    assert_not ReadingProgress.exists?(@reading.id)
    assert_select 'turbo-stream[action=remove][target=?]', "reading-progress-#{@reading.id}"
    assert_includes response.body, 'Прибрано з читальні'
  end

  test 'moving the last row redraws the tab with its empty state' do
    reading_progresses(:two).update!(status: :postponed)

    move(@reading, :dropped)

    assert_select 'turbo-stream[action=update][target=library-list]', text: /Тут так порожньо/
    assert_includes response.body, 'Перенесено до «Покинуто»'
  end

  private

  def move(reading, status)
    patch update_reading_progress_path(reading), params: { status:, current_section: :active }, as: :turbo_stream
  end
end
