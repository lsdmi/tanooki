# frozen_string_literal: true

require 'test_helper'

class FictionsChapterSectionControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @fiction = fictions(:one)
  end

  test 'chapter_section returns chapter list html for guests' do
    chapter_ids = @fiction.chapters.pluck(:id).join(',')

    get chapter_section_fiction_path(@fiction, section: 'r-1-100', order: 'asc', chapter_ids: chapter_ids)

    assert_response :success
    assert_select 'ul li'
    assert_no_match(/turbo-frame/, response.body)
  end
end
