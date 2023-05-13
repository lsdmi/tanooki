# frozen_string_literal: true

require 'test_helper'

module Admin
  class ChaptersControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    def setup
      sign_in users(:user_one)
      @chapter = chapters(:one)
    end

    test 'should get new' do
      get new_admin_chapter_url(fiction: 'one')
      assert_response :success
    end

    test 'should create chapter' do
      assert_difference('Chapter.count') do
        post admin_chapters_url, params: {
          chapter: {
            content: @chapter.content,
            fiction_id: @chapter.fiction_id,
            number: @chapter.number,
            title: @chapter.title,
            user_id: @chapter.user_id
          }
        }
      end

      assert_redirected_to admin_fictions_path
    end

    test 'should not create chapter with invalid data' do
      assert_no_difference('Chapter.count') do
        post admin_chapters_url, params: { chapter: { content: '', fiction_id: '', number: '', title: '' } }
      end

      assert_response :unprocessable_entity
    end

    test 'should get edit' do
      get edit_admin_chapter_url(@chapter)
      assert_response :success
    end

    test 'should update chapter' do
      patch admin_chapter_url(@chapter), params: {
        chapter: {
          content: @chapter.content,
          fiction_id: @chapter.fiction_id,
          number: @chapter.number,
          title: @chapter.title
        }
      }
      assert_redirected_to admin_fictions_path
    end

    test 'should not update chapter with invalid data' do
      patch admin_chapter_url(@chapter), params: { chapter: { content: '', number: '', title: '' } }
      assert_response :unprocessable_entity
    end

    test 'should destroy chapter' do
      assert_difference('Chapter.count', -1) do
        delete admin_chapter_url(@chapter)
      end

      assert_response :success
    end
  end
end
