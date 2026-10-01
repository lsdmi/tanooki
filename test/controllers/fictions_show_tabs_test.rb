# frozen_string_literal: true

require 'test_helper'

class FictionsShowTabsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:user_one)
    @fiction = fictions(:one)
  end

  test 'tab labels carry chapter and comment counts' do
    get fiction_url(@fiction)

    assert_select '[role=tablist] [role=tab]', 3
    assert_select '#fiction-tab-chapters', text: /Розділи · #{@fiction.chapter_count}/
    assert_select '#fiction-tab-comments', text: /Коментарі · #{@fiction.comments_count}/
  end

  test 'About is open before reading starts' do
    reading_progresses(:one).update!(resume_at: nil)
    ReadingChapterRead.where(user: users(:user_one)).delete_all

    get fiction_url(@fiction)

    assert_select '#fiction-tab-about[aria-selected=true][tabindex="0"]'
    assert_select '#fiction-tab-chapters[aria-selected=false][tabindex="-1"]'
    assert_select '#fiction-panel-about[role=tabpanel]:not([hidden])'
  end

  test 'hidden panels still hold the chapter list and a lazy comments frame' do
    reading_progresses(:one).update!(resume_at: nil)
    ReadingChapterRead.where(user: users(:user_one)).delete_all

    get fiction_url(@fiction)

    assert_select '#fiction-panel-chapters[hidden] turbo-frame#sort-chapters'
    assert_select '#fiction-panel-comments[hidden] turbo-frame#fiction_comments[loading=lazy]'
  end

  test 'Chapters is open for a reader who has started' do
    reading_progresses(:one).update!(resume_at: 1.hour.ago)

    get fiction_url(@fiction)

    assert_select '#fiction-tab-chapters[aria-selected=true]'
    assert_select '#fiction-panel-chapters:not([hidden])'
    assert_select '#fiction-panel-about[hidden]'
  end

  test 'similar fictions sit below the tab panels' do
    get fiction_url(@fiction)

    assert_select '[role=tabpanel] turbo-frame#fiction_similar', 0
    assert_select 'main > turbo-frame#fiction_similar'
  end
end
