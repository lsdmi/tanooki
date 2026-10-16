# frozen_string_literal: true

require 'test_helper'

class ChaptersLazyDrawersTest < ActionDispatch::IntegrationTest
  setup do
    @chapter = chapters(:one)
  end

  test 'chapter show shells the comments drawer without the comment tree' do
    get chapter_url(@chapter)

    assert_response :success
    assert_select 'turbo-frame#reader-comments-list[data-comments-drawer-src-value]'
    assert_select 'turbo-frame#reader-comments-list', text: /Завантаження коментарів/
  end

  test 'chapter show shells the chapter list drawer without the TOC' do
    get chapter_url(@chapter)

    assert_response :success
    assert_select 'turbo-frame#reader-chapter-list[data-chapter-drawer-src-value]'
    assert_select 'turbo-frame#reader-chapter-list', text: /Завантаження змісту/
  end

  test 'chapter show omits comment articles and the loaded TOC frame' do
    get chapter_url(@chapter)

    assert_response :success
    assert_select 'turbo-frame#sort-chapters-reader-drawer', count: 0
    assert_select '#comments article', count: 0
  end

  test 'comments frame returns the comment list' do
    get comments_chapter_url(@chapter)

    assert_response :success
    assert_select 'turbo-frame#reader-comments-list'
    assert_select 'turbo-frame#comments'
  end

  test 'chapter_list frame returns the TOC list' do
    get chapter_list_chapter_url(@chapter)

    assert_response :success
    assert_select 'turbo-frame#reader-chapter-list'
    assert_select 'turbo-frame#sort-chapters-reader-drawer'
  end
end
