# frozen_string_literal: true

require 'test_helper'

module Chapters
  class ReadsFictionListTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      @user = users(:user_one)
      @chapter = chapters(:one)
      @row = "li#chapter_list_chapter_#{@chapter.id}"
      ReadingChapterRead.where(user: @user).delete_all
      reading_progresses(:one).update!(chapter: chapters(:two), status: :active)
    end

    test 'signed-in fiction page rows offer the toggle' do
      sign_in @user
      get fiction_url(fictions(:one))

      assert_select "#{@row} form[action=?] button[aria-label=?]",
                    chapter_read_path(@chapter), I18n.t('chapters.reader_chapter_drawer.mark_read')
    end

    test 'guests get no toggle on the fiction page' do
      get fiction_url(fictions(:one))

      assert_select '#chapters-list form, #chapters-list li[id]', count: 0
    end

    test 'a finished fiction shows read icons without a toggle' do
      reading_progresses(:one).update!(status: :finished)
      sign_in @user
      get fiction_url(fictions(:one))

      assert_select "#{@row} form", count: 0
      assert_select "#{@row} span[role=img][aria-label=?]", I18n.t('chapters.reader_chapter_drawer.progress_read')
    end

    test 'mark read from the fiction page replaces the fiction page row' do
      sign_in @user
      post chapter_read_url(@chapter), params: { fiction_list: 1 }, as: :turbo_stream

      assert_select 'turbo-stream[action=replace][target=?]', "chapter_list_chapter_#{@chapter.id}"
      assert_select "#{@row}[data-chapter-status=read] button[aria-label=?]",
                    I18n.t('chapters.reader_chapter_drawer.mark_unread')
    end

    test 'mark unread from the fiction page brings the toggle back to mark read' do
      sign_in @user
      post chapter_read_url(@chapter), params: { fiction_list: 1 }, as: :turbo_stream
      delete chapter_read_url(@chapter), params: { fiction_list: 1 }, as: :turbo_stream

      assert_select "#{@row}[data-chapter-status=unread] button[aria-label=?]",
                    I18n.t('chapters.reader_chapter_drawer.mark_read')
    end

    test 'reading the continue chapter moves the continue row and the chip to the next chapter' do
      following = continue_from_two
      post chapter_read_url(chapters(:two)), params: { fiction_list: 1 }, as: :turbo_stream

      assert_select "#{row(chapters(:two))}[data-chapter-status=read]:not([data-chapter-continue])"
      assert_select "#{row(following)}[data-chapter-status=unread][data-chapter-continue]"
      assert_select 'turbo-stream[action=update][target=chapter_continue_chip] template',
                    text: /До поточного розділу · 3/
    end

    test 'unmarking it brings the continue row back' do
      following = continue_from_two
      post chapter_read_url(chapters(:two)), params: { fiction_list: 1 }, as: :turbo_stream
      delete chapter_read_url(chapters(:two)), params: { fiction_list: 1 }, as: :turbo_stream

      assert_select "#{row(chapters(:two))}[data-chapter-continue]"
      assert_select "#{row(following)}:not([data-chapter-continue])"
    end

    test 'a toggle that leaves the continue target alone re-renders only its own row' do
      continue_from_two
      post chapter_read_url(@chapter), params: { fiction_list: 1 }, as: :turbo_stream

      assert_select 'turbo-stream', count: 1
    end

    private

    def row(chapter) = "li#chapter_list_chapter_#{chapter.id}"

    def continue_from_two
      reading_progresses(:one).update!(resume_at: Time.current)
      sign_in @user
      Chapter.create!(fiction: fictions(:one), user: @user, title: 'Chapter 3', number: 3, content: 'x' * 500,
                      scanlator_ids: [scanlators(:one).id])
    end
  end
end
