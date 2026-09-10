# frozen_string_literal: true

require 'test_helper'

class CatalogListingNudgesPostedAfterCompleteControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @fiction = fictions(:one)
    @fiction.scanlator_ids = @fiction.scanlators.ids
    @fiction.update!(
      chapter_count: 6,
      expected_chapters: 10,
      completed_at: 2.days.ago,
      last_chapter_at: 1.day.ago,
      listing_nudge_dismissals: {}
    )
    sign_in users(:user_one)
  end

  test 'readings show asks to clear complete after a later chapter' do
    get reading_url(@fiction)

    assert_response :success
    assert_match 'Ви виклали розділ після позначки', response.body
    assert_select 'form[action=?]', reopen_fiction_listing_nudge_path(@fiction)
  end

  test 'edit page asks to clear complete after a later chapter' do
    get edit_fiction_url(@fiction)

    assert_response :success
    assert_match 'Ви виклали розділ після позначки', response.body
  end

  test 'edit page keeps the reopen nudge outside the fiction form' do
    get edit_fiction_url(@fiction)

    assert_select 'form form', false, 'nested forms break CSRF and submit to fictions#update'
    assert_select 'form[action=?]', reopen_fiction_listing_nudge_path(@fiction)
  end

  test 'reopen clears completed_at' do
    post reopen_fiction_listing_nudge_url(@fiction)

    assert_redirected_to reading_path(@fiction)
    assert_nil @fiction.reload.completed_at
  end

  test 'dismiss keeps completed_at' do
    last_public = @fiction.last_chapter_at

    post dismiss_fiction_listing_nudge_url(@fiction)

    assert_redirected_to reading_path(@fiction)
    assert_equal last_public.to_i, @fiction.reload.listing_nudge_dismissals['posted_after_complete']
    assert_not_nil @fiction.completed_at
  end

  test 'guest cannot reopen' do
    sign_out users(:user_one)

    post reopen_fiction_listing_nudge_url(@fiction)

    assert_redirected_to new_user_session_path
    assert_not_nil @fiction.reload.completed_at
  end

  test 'unrelated user cannot reopen' do
    sign_in users(:user_two)

    post reopen_fiction_listing_nudge_url(@fiction)

    assert_redirected_to root_path
    assert_not_nil @fiction.reload.completed_at
  end
end
