# frozen_string_literal: true

require 'test_helper'

class ChaptersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @chapter = chapters(:one)
  end

  test 'should get show' do
    get chapter_url(@chapter)
    assert_response :success
  end

  test 'should load advertisement' do
    get chapter_url(@chapter)
    assert_not_nil assigns(:more_ads)
  end

  test 'should get comments' do
    @chapter.comments << comments(:comment_one)
    get chapter_url(@chapter)
    assert_equal @chapter.comments, assigns(:comments)
  end

  test 'should get next chapter' do
    get chapter_path(@chapter)
    assert_equal chapters(:two), assigns(:next_chapter)
  end
end
