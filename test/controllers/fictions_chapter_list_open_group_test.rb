# frozen_string_literal: true

require 'test_helper'

class FictionsChapterListOpenGroupTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  OPEN_PAGER = '#chapters-list .accordion-content:not(.hidden) [data-controller="chapter-group-pager"]'

  setup do
    @user = users(:user_one)
    @fiction = fictions(:one)
    ReadingChapterRead.where(user: @user).delete_all
    @later = (101..135).map do |number|
      Chapter.create!(fiction: @fiction, user: @user, title: "Chapter #{number}", number:, content: 'x' * 500,
                      scanlator_ids: [scanlators(:one).id])
    end
  end

  test 'a reader gets the group with the continue chapter open and the others lazy' do
    resume_at(chapters(:two))
    sign_in @user
    get fiction_url(@fiction)

    assert_select "#{OPEN_PAGER}[data-chapter-group-pager-url-value*='section=r-1-100']"
    assert_select '#chapters-list .accordion-content:not(.hidden)', count: 1
    assert_select "#chapters-list [data-chapter-section-url*='section=r-101-200']"
  end

  test 'the list knows which row to bring up' do
    resume_at(chapters(:two))
    sign_in @user
    get fiction_url(@fiction)

    assert_select '#chapters-list li[data-chapter-continue]', count: 1
    assert_select "#chapters-list li#chapter_list_chapter_#{chapters(:two).id}[data-chapter-continue]"
  end

  test 'the open group renders through the continue row and keeps it on phones' do
    resume_at(@later.find { |chapter| chapter.number == 110 })
    sign_in @user
    get fiction_url(@fiction)

    assert_select "#{OPEN_PAGER} > ul > li", count: 30
    assert_select "#{OPEN_PAGER} > ul[class*='nth-child']", count: 0
  end

  test 'guests get the first group in the current sort' do
    get fiction_url(@fiction)

    assert_select "#{OPEN_PAGER}[data-chapter-group-pager-url-value*='section=r-101-200']"
    assert_select "#{OPEN_PAGER} > ul[class*='nth-child']"
    assert_select '[data-chapter-continue]', count: 0
  end

  test 'a reader who has read everything gets the first group' do
    resume_at(chapters(:two))
    reading_progresses(:one).update!(status: :finished)
    sign_in @user
    get fiction_url(@fiction)

    assert_select "#{OPEN_PAGER}[data-chapter-group-pager-url-value*='section=r-101-200']"
  end

  private

  def resume_at(chapter)
    reading_progresses(:one).update!(chapter:, resume_at: Time.current, status: :active)
  end
end
