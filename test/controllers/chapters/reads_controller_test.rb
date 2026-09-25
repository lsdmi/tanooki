# frozen_string_literal: true

require 'test_helper'

module Chapters
  class ReadsControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      @user = users(:user_one)
      @chapter = chapters(:one)
      sign_in @user
      ReadingChapterRead.where(user: @user).delete_all
    end

    test 'mark read stores a manual read' do
      post chapter_read_url(@chapter), as: :turbo_stream

      assert_response :success
      assert_equal 'manual', ReadingChapterRead.find_by!(user: @user, chapter: @chapter).source
    end

    test 'mark read replaces the drawer row with an unread toggle' do
      post chapter_read_url(@chapter), params: { current_chapter_id: chapters(:two).id }, as: :turbo_stream

      assert_select 'turbo-stream[action=replace][target=?]', "reader_drawer_chapter_#{@chapter.id}"
      assert_select 'button[aria-label=?]', I18n.t('chapters.reader_chapter_drawer.mark_unread')
    end

    test 'replaced row carries the read state for drawer search results' do
      post chapter_read_url(@chapter), as: :turbo_stream

      assert_select 'li[data-chapter-drawer-search-target=row][data-chapter-id=?][data-chapter-read=true]',
                    @chapter.id.to_s
    end

    test 'toggle refreshes every listed translation row of the chapter' do
      other_team = Chapter.create!(fiction: @chapter.fiction, user: @user, title: 'Other team', number: @chapter.number,
                                   content: 'x' * 500, scanlator_ids: [scanlators(:two).id])
      post chapter_read_url(@chapter), as: :turbo_stream

      assert_select 'turbo-stream[action=replace][target=?]', "reader_drawer_chapter_#{other_team.id}"
    end

    test 'mark unread removes the read and offers mark read again' do
      post chapter_read_url(@chapter), as: :turbo_stream
      delete chapter_read_url(@chapter), as: :turbo_stream

      assert_not ReadingChapterRead.exists?(user: @user, chapter: @chapter)
      assert_select 'button[aria-label=?]', I18n.t('chapters.reader_chapter_drawer.mark_read')
    end

    test 'mark unread of a chapter that was never read succeeds without writing' do
      assert_no_difference -> { ReadingChapterRead.count } do
        delete chapter_read_url(@chapter), as: :turbo_stream
      end

      assert_response :success
    end

    test 'mark read twice keeps a single read' do
      post chapter_read_url(@chapter), as: :turbo_stream

      assert_no_difference -> { ReadingChapterRead.count } do
        post chapter_read_url(@chapter), as: :turbo_stream
      end
    end

    test 'draft chapter is not found' do
      @chapter.update!(status: :draft)
      post chapter_read_url(@chapter), as: :turbo_stream

      assert_response :not_found
    end

    test 'html request redirects back to the chapter' do
      post chapter_read_url(@chapter)

      assert_redirected_to chapter_path(@chapter)
    end

    test 'reader drawer rows offer the toggle' do
      get chapter_url(chapters(:two))

      assert_select '#reader-chapter-list-panel form[action=?] button[aria-label=?]',
                    chapter_read_path(chapters(:two)), I18n.t('chapters.reader_chapter_drawer.mark_read')
    end

    test 'reader drawer rows have no toggle for guests' do
      sign_out @user
      get chapter_url(chapters(:two))

      assert_select '#reader-chapter-list-panel form[action=?]', chapter_read_path(chapters(:two)), count: 0
    end

    test 'guest cannot mark chapters' do
      sign_out @user

      assert_no_difference -> { ReadingChapterRead.count } do
        post chapter_read_url(@chapter)
      end
    end
  end
end
