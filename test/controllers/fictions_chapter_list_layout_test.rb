# frozen_string_literal: true

require 'test_helper'

class FictionsChapterListLayoutTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:user_one)
    @fiction = fictions(:one)
    ReadingChapterRead.where(user: @user).delete_all
    reading_progresses(:one).update!(chapter: chapters(:two), status: :active)
    ReadingChapterRead.create!(user: @user, fiction: @fiction, chapter: chapters(:one),
                               completed_at: Time.current, source: 'scroll')
  end

  test 'a reader sees read counts in the tab header and the group header' do
    sign_in @user
    get fiction_url(@fiction)

    assert_select '#sort-chapters > section > div p', text: '1 з 2 прочитано'
    assert_select '#chapters-list .accordion-header', text: /1 з 2 прочитано/
    assert_select '#chapters-list .accordion-header [role=progressbar][aria-valuenow="1"][aria-valuemax="2"]'
  end

  test 'a reader gets the legend with the manual marking hint' do
    sign_in @user
    get fiction_url(@fiction)

    states = css_select('#sort-chapters section > div:last-child > span.inline-flex').map { |state| state.text.strip }

    assert_equal ['Непрочитаний', 'Читаю зараз', 'Прочитаний'], states
    assert_select '#sort-chapters section > div:last-child span', text: 'Натисніть на статус, щоб змінити його вручну'
  end

  test 'a finished fiction keeps the legend but drops the hint' do
    reading_progresses(:one).update!(status: :finished)
    sign_in @user
    get fiction_url(@fiction)

    assert_select '#chapters-list .accordion-header', text: /2 з 2 прочитано/
    assert_select 'span', text: 'Натисніть на статус, щоб змінити його вручну', count: 0
  end

  test 'guests see chapter counts and no legend' do
    get fiction_url(@fiction)

    assert_select '#chapters-list .accordion-header', text: /2 розділи/
    assert_select '#chapters-list [role=progressbar]', count: 0
    assert_select 'span', text: 'Непрочитаний', count: 0
  end

  test 'rows title the chapter for desktop and drop the number prefix on mobile' do
    chapters(:one).update!(title: 'Директор Хо')
    get fiction_url(@fiction)

    row = "li a[href='#{chapter_path(chapters(:one))}']"

    assert_select "#{row} span.hidden.md\\:inline", text: 'Розділ 1 — Директор Хо'
    assert_select "#{row} span.md\\:hidden", text: 'Директор Хо'
  end
end
