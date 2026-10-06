# frozen_string_literal: true

require 'test_helper'

module Fictions
  class ChapterReadFilterTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      @user = users(:user_one)
      @fiction = fictions(:one)
      ReadingChapterRead.where(user: @user).delete_all
      reading_progresses(:one).update!(chapter: chapters(:two), status: :active, resume_at: Time.current)
      @third = Chapter.create!(fiction: @fiction, user: @user, title: 'Chapter 3', number: 3, content: 'x' * 500,
                               scanlator_ids: [scanlators(:one).id])
      ReadingChapterRead.create!(user: @user, fiction: @fiction, chapter: chapters(:one), completed_at: Time.current,
                                 source: 'manual')
      sign_in @user
    end

    test 'readers get the filter with «Усі» selected and no login nudge' do
      get fiction_url(@fiction)

      assert_select '[role=group][aria-label=?] button[aria-pressed=true]', 'Показати розділи', text: 'Усі'
      assert_select 'a[href*="/login"]', text: 'Увійти', count: 0
    end

    test 'guests get the login nudge instead of the filter' do
      sign_out @user
      get fiction_url(@fiction)

      assert_select '[role=group][aria-label=?]', 'Показати розділи', count: 0
      assert_select 'a[href=?][data-turbo-frame=_top]',
                    new_user_session_path(return_to: fiction_path(@fiction, anchor: 'chapters')), text: 'Увійти'
    end

    test 'unread keeps the unread and in-progress rows' do
      post chapter_filter_fiction_url(@fiction, order: :asc, filter: 'unread'), as: :turbo_stream

      assert_equal [chapters(:two), @third].map { |chapter| "chapter_list_chapter_#{chapter.id}" }, row_ids
      assert_select 'button[aria-pressed=true]', text: 'Непрочитані'
    end

    test 'read keeps the read rows, and the group header still counts the whole group' do
      post chapter_filter_fiction_url(@fiction, order: :asc, filter: 'read'), as: :turbo_stream

      assert_equal ["chapter_list_chapter_#{chapters(:one).id}"], row_ids
      assert_select '#chapter_group_progress_r-1-100', text: /1 з 3 прочитано/
    end

    test 'the sort keeps the filter' do
      post chapter_filter_fiction_url(@fiction, order: :asc, filter: 'unread'), as: :turbo_stream

      assert_select 'form[action=?]', toggle_order_fiction_path(@fiction, order: :asc, filter: 'unread')
    end

    test 'nothing read shows the empty state' do
      ReadingChapterRead.where(user: @user).delete_all
      post chapter_filter_fiction_url(@fiction, order: :asc, filter: 'read'), as: :turbo_stream

      assert_select 'p', text: 'Ви ще не прочитали жодного розділу'
      assert_select '.accordion', count: 0
    end

    test 'group pages follow the filter' do
      get chapter_section_fiction_path(@fiction, section: 'r-1-100', order: 'asc', filter: 'unread', limit: 1)

      assert_equal ["chapter_list_chapter_#{chapters(:two).id}"], row_ids
      assert_select '[data-chapter-group-pager-total-value="2"][data-chapter-group-pager-url-value*="filter=unread"]'
    end

    test 'a jump to a row the filter hides says so' do
      get chapter_jump_fiction_url(@fiction, order: :asc, filter: 'unread', number: '1')

      assert_equal 'Розділ 1 приховано фільтром', response.parsed_body['error']
    end

    private

    def row_ids = css_select('li[id^=chapter_list_chapter_]').pluck('id')
  end
end
