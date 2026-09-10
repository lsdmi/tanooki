# frozen_string_literal: true

require 'test_helper'

class CatalogListingNudgesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @fiction = fictions(:one)
    @fiction.scanlator_ids = @fiction.scanlators.ids
    @fiction.update!(chapter_count: 5, expected_chapters: 5, completed_at: nil, listing_nudge_dismissals: {})
    sign_in users(:user_one)
  end

  test 'readings show asks to complete when the plan is reached' do
    get reading_url(@fiction)

    assert_response :success
    assert_match 'Схоже, ви виклали всі 5 розділів', response.body
  end

  test 'edit form asks to complete when the plan is reached' do
    get edit_fiction_url(@fiction)

    assert_response :success
    assert_match 'Схоже, ви виклали всі 5 розділів', response.body
  end

  test 'edit page keeps the nudge outside the fiction form' do
    get edit_fiction_url(@fiction)

    assert_select 'form form', false, 'nested forms break CSRF and submit to fictions#update'
    assert_select 'form[action=?]', complete_fiction_listing_nudge_path(@fiction)
  end

  test 'complete stamps completed_at' do
    post complete_fiction_listing_nudge_url(@fiction)

    assert_redirected_to reading_path(@fiction)
    assert_not_nil @fiction.reload.completed_at
  end

  test 'dismiss stores the skipped plan' do
    post dismiss_fiction_listing_nudge_url(@fiction)

    assert_redirected_to reading_path(@fiction)
    assert_equal 5, @fiction.reload.listing_nudge_dismissals['plan_reached']
    assert_nil @fiction.completed_at
  end

  test 'readings show asks to complete when the listing has gone quiet' do
    @fiction.update!(
      expected_chapters: nil,
      last_chapter_at: FictionListingProgress::STALE_AFTER.ago - 1.day
    )

    get reading_url(@fiction)

    assert_response :success
    assert_match 'Розділів немає вже 3 місяці', response.body
  end

  test 'edit page asks to complete when the listing has gone quiet' do
    @fiction.update!(
      expected_chapters: nil,
      last_chapter_at: FictionListingProgress::STALE_AFTER.ago - 1.day
    )

    get edit_fiction_url(@fiction)

    assert_response :success
    assert_match 'Розділів немає вже 3 місяці', response.body
  end

  test 'dismiss stores the skipped silence' do
    last_public = FictionListingProgress::STALE_AFTER.ago - 1.day
    @fiction.update!(expected_chapters: nil, last_chapter_at: last_public)

    post dismiss_fiction_listing_nudge_url(@fiction)

    assert_redirected_to reading_path(@fiction)
    assert_equal last_public.to_i, @fiction.reload.listing_nudge_dismissals['gone_quiet']
    assert_nil @fiction.completed_at
  end

  test 'guest cannot complete' do
    sign_out users(:user_one)

    post complete_fiction_listing_nudge_url(@fiction)

    assert_redirected_to new_user_session_path
    assert_nil @fiction.reload.completed_at
  end

  test 'unrelated user cannot complete' do
    sign_in users(:user_two)

    post complete_fiction_listing_nudge_url(@fiction)

    assert_redirected_to root_path
    assert_nil @fiction.reload.completed_at
  end
end
