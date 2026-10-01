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

  test 'the team toolbar sits above the tab panels when Chapters opens for a team member' do
    sign_in_team_member
    ReadingProgress.create!(user: users(:user_one_one_zero), fiction: @fiction, chapter: chapters(:one),
                            resume_at: 1.hour.ago)

    get fiction_url(@fiction)

    assert_select '#fiction-tab-chapters[aria-selected=true]'
    assert_select 'main > section[aria-labelledby="fiction-team-toolbar-title"] a', text: 'Додати розділ'
    assert_select 'main > section[aria-labelledby="fiction-team-toolbar-title"] + section#fiction-panel-about'
  end

  test 'team members do not get the invite-to-translate card' do
    sign_in_team_member

    get fiction_url(@fiction)

    assert_not_includes response.body, 'Додайте нові розділи!'
  end

  test 'readers outside the team get the invite card and no team toolbar' do
    sign_in users(:user_two)

    get fiction_url(@fiction)

    assert_select 'section[aria-labelledby="fiction-team-toolbar-title"]', 0
    assert_includes response.body, 'Додайте нові розділи!'
  end

  test 'similar fictions sit below the tab panels' do
    get fiction_url(@fiction)

    assert_select '[role=tabpanel] turbo-frame#fiction_similar', 0
    assert_select 'main > turbo-frame#fiction_similar'
  end

  private

  def sign_in_team_member
    member = users(:user_one_one_zero)
    ScanlatorUser.create!(user: member, scanlator: scanlators(:one))
    sign_in member
  end
end
