# frozen_string_literal: true

require 'test_helper'

class CatalogListingNudgesStalePlanControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @fiction = fictions(:one)
    @fiction.scanlator_ids = @fiction.scanlators.ids
    @fiction.update!(chapter_count: 8, expected_chapters: 5, completed_at: nil, listing_nudge_dismissals: {})
    sign_in users(:user_one)
  end

  test 'readings show asks to raise or clear a stale plan' do
    get reading_url(@fiction)

    assert_response :success
    assert_match 'Уже 8 розділів, план був 5', response.body
  end

  test 'edit page asks to raise or clear a stale plan' do
    get edit_fiction_url(@fiction)

    assert_response :success
    assert_match 'Уже 8 розділів, план був 5', response.body
  end

  test 'edit page keeps stale-plan actions outside the fiction form' do
    get edit_fiction_url(@fiction)

    assert_select 'form form', false, 'nested forms break CSRF and submit to fictions#update'
    assert_select 'form[action=?]', raise_expected_fiction_listing_nudge_path(@fiction)
    assert_select 'form[action=?]', clear_expected_fiction_listing_nudge_path(@fiction)
  end

  test 'raise expected updates the plan' do
    post raise_expected_fiction_listing_nudge_url(@fiction)

    assert_redirected_to reading_path(@fiction)
    assert_equal 8, @fiction.reload.expected_chapters
  end

  test 'clear expected removes the plan' do
    post clear_expected_fiction_listing_nudge_url(@fiction)

    assert_redirected_to reading_path(@fiction)
    assert_nil @fiction.reload.expected_chapters
  end

  test 'dismiss stores the skipped overrun' do
    post dismiss_fiction_listing_nudge_url(@fiction)

    assert_redirected_to reading_path(@fiction)
    assert_equal 8, @fiction.reload.listing_nudge_dismissals['stale_plan']
    assert_equal 5, @fiction.expected_chapters
  end

  test 'guest cannot raise expected' do
    sign_out users(:user_one)

    post raise_expected_fiction_listing_nudge_url(@fiction)

    assert_redirected_to new_user_session_path
    assert_equal 5, @fiction.reload.expected_chapters
  end
end
