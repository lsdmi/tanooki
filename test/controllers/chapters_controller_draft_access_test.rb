# frozen_string_literal: true

require 'test_helper'

class ChaptersControllerDraftAccessTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @chapter = chapters(:one)
    @chapter.update!(status: :draft, scanlator_ids: @chapter.scanlators.ids)
  end

  test 'team member is sent from draft show to edit' do
    sign_in users(:user_one)
    get chapter_url(@chapter)

    assert_redirected_to edit_chapter_path(@chapter)
  end

  test 'guest is redirected away from draft show' do
    get chapter_url(@chapter)

    assert_redirected_to fiction_path(@chapter.fiction)
  end

  test 'guest cannot guess-edit a draft chapter' do
    get edit_chapter_url(@chapter)

    assert_redirected_to new_user_session_path
  end

  test 'outsider cannot guess-edit a draft chapter' do
    sign_in users(:user_two)
    get edit_chapter_url(@chapter)

    assert_redirected_to root_path
  end

  test 'guest cannot patch a draft chapter' do
    patch chapter_url(@chapter), params: { chapter: { title: 'Hijacked' } }

    assert_redirected_to new_user_session_path
    assert_not_equal 'Hijacked', @chapter.reload.title
  end

  test 'record_progress on a draft does not change reading progress' do
    sign_in users(:user_one)
    progress = reading_progresses(:one)
    progress.update!(chapter: chapters(:two))

    post record_progress_chapter_url(@chapter)

    assert_response :no_content
    assert_equal chapters(:two).id, progress.reload.chapter_id
  end
end
