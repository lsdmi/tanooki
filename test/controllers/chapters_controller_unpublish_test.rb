# frozen_string_literal: true

require 'test_helper'

class ChaptersControllerUnpublishTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:user_one)
    @chapter = chapters(:one)
  end

  test 'draft intent unpublishes a live chapter' do
    patch chapter_url(@chapter), params: unpublish_params

    assert_predicate @chapter.reload, :draft?
    assert_redirected_to edit_chapter_path(@chapter)
  end

  test 'unpublished chapter is hidden from guests' do
    patch chapter_url(@chapter), params: unpublish_params
    sign_out :user
    get chapter_url(@chapter)

    assert_redirected_to fiction_path(@chapter.fiction)
  end

  private

  def unpublish_params
    {
      intent: 'draft',
      chapter: {
        content: @chapter.content,
        fiction_id: @chapter.fiction_id,
        number: @chapter.number,
        scanlator_ids: [1],
        title: @chapter.title
      }
    }
  end
end
