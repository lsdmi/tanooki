# frozen_string_literal: true

require 'test_helper'

class StudioListingNudgeFlagsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @fiction = fictions(:one)
    @fiction.scanlator_ids = @fiction.scanlators.ids
    @fiction.update!(
      chapter_count: 5,
      expected_chapters: 5,
      completed_at: nil,
      listing_nudge_dismissals: {}
    )
    sign_in users(:user_one)
  end

  test 'writings tab shows listing nudge chip for plan reached' do
    get studio_index_path(tab: 'writings')

    assert_response :success
    assert_match 'Схоже, ви виклали всі 5 розділів', response.body
    assert_select 'a[href=?]', reading_path(@fiction)
  end

  test 'writings tab shows listing nudge chip for gone quiet' do
    @fiction.update!(
      expected_chapters: nil,
      last_chapter_at: FictionListingProgress::STALE_AFTER.ago - 1.day
    )

    get studio_index_path(tab: 'writings')

    assert_response :success
    assert_match 'Розділів немає вже 3 місяці', response.body
  end

  test 'writings tab shows listing nudge chip for posted after complete' do
    @fiction.update!(
      expected_chapters: 10,
      completed_at: 2.days.ago,
      last_chapter_at: 1.day.ago
    )

    get studio_index_path(tab: 'writings')

    assert_response :success
    assert_match 'Ви виклали розділ після позначки', response.body
  end

  test 'writings tab hides the chip when there is no nudge' do
    @fiction.update!(expected_chapters: 8)

    get studio_index_path(tab: 'writings')

    assert_response :success
    assert_no_match 'Схоже, ви виклали всі 5 розділів', response.body
    assert_no_match 'Розділів немає вже 3 місяці', response.body
  end

  test 'writings tab hides the chip when the nudge was dismissed' do
    @fiction.update!(listing_nudge_dismissals: { 'plan_reached' => 5 })

    get studio_index_path(tab: 'writings')

    assert_response :success
    assert_no_match 'Схоже, ви виклали всі 5 розділів', response.body
  end

  test 'listing nudge chip escapes the studio turbo frame' do
    get studio_index_path(tab: 'writings')

    assert_select 'a[href=?][data-turbo-frame=_top]', reading_path(@fiction)
  end
end
