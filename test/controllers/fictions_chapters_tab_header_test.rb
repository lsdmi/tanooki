# frozen_string_literal: true

require 'test_helper'

class FictionsChaptersTabHeaderTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @fiction = fictions(:one)
    @user = users(:user_one)
    ReadingChapterRead.where(user: @user).delete_all
    sign_in @user
  end

  test 'header shows the chapter count, the latest chapter and the current sort' do
    get fiction_url(@fiction)

    latest = Library::ChapterCatalog.ordered_chapters_desc(@fiction, viewer: @user).first
    count = Library::ChapterCatalog.chapters_size(@fiction, viewer: @user)
    latest_line = "Останній розділ: #{Chapters::Formatting.format_decimal(latest.number)} · " \
                  "#{I18n.l(latest.public_at, format: :shortest)}"

    assert_select '#sort-chapters p', text: I18n.t('fictions.chapters_tab.count', count:)
    assert_select '#sort-chapters p', text: latest_line
    assert_select '#toggle-fictions-order[title=?]', 'Показати від першого розділу', text: /Новіші/
  end

  test 'toggle_order relabels the sort toggle' do
    post toggle_order_fiction_path(@fiction, order: :desc),
         headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

    assert_includes response.body, 'Старіші'
    assert_includes response.body, 'title="Показати від останнього розділу"'
  end

  test 'section EPUB download is an icon button with a screen-reader label' do
    get fiction_url(@fiction)

    assert_select '#sort-chapters [data-epub-download-target="button"][title="Завантажити EPUB"] .sr-only',
                  text: 'Завантажити EPUB'
  end
end
