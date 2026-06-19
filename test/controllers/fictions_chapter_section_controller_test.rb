# frozen_string_literal: true

require 'test_helper'

class FictionsChapterSectionControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @fiction = fictions(:one)
  end

  test 'chapter_section returns chapter list html without chapter_ids' do
    get chapter_section_fiction_path(@fiction, section: 'r-1-100', order: 'asc')

    assert_response :success
    assert_select 'ul li'
  end

  test 'chapter_section returns chapter list html for guests' do
    get chapter_section_fiction_path(@fiction, section: 'r-1-100', order: 'asc')

    assert_response :success
    assert_select 'ul li'
  end

  test 'chapter_section chapter links omit turbo preload' do
    get chapter_section_fiction_path(@fiction, section: 'r-1-100', order: 'asc')

    assert_select 'a[data-turbo-frame="_top"]'
    assert_select 'a[data-turbo-preload="true"]', count: 0
  end
end
