# frozen_string_literal: true

require 'test_helper'

class FictionsMergedRedirectTest < ActionDispatch::IntegrationTest
  setup do
    @source = fictions(:two)
    @target = fictions(:one)
    @source.destroy!
    deleted = Fiction.with_deleted.find(@source.id)
    deleted.merged_into = @target
    deleted.save!(validate: false)
  end

  test 'old fiction url redirects to the surviving fiction' do
    get fiction_path(@source)

    assert_response :moved_permanently
    assert_redirected_to fiction_path(@target)
  end

  test 'comments and chapter section keep their route' do
    get comments_fiction_path(@source)

    assert_redirected_to comments_fiction_path(@target)

    get chapter_section_fiction_path(@source, order: 'asc')

    assert_redirected_to chapter_section_fiction_path(@target, order: 'asc')
  end

  test 'details redirects to the surviving fiction' do
    get details_fiction_path(@source), as: :turbo_stream

    assert_response :moved_permanently
    assert_redirected_to details_fiction_path(@target)
  end

  test 'a missing slug is not found' do
    get fiction_path('not-a-fiction')

    assert_response :not_found
  end
end
