# frozen_string_literal: true

require 'test_helper'

class CatalogListingNudgesOptionalExpectedControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @fiction = fictions(:one)
    @fiction.scanlator_ids = @fiction.scanlators.ids
    @fiction.update!(
      chapter_count: Catalog::ListingNudge::OPTIONAL_EXPECTED_AFTER,
      expected_chapters: nil,
      completed_at: nil,
      last_chapter_at: 1.day.ago,
      listing_nudge_dismissals: {}
    )
    sign_in users(:user_one)
  end

  test 'readings show soft asks for an expected plan' do
    get reading_url(@fiction)

    assert_response :success
    assert_match 'Знаєте, скільки розділів буде?', response.body
    assert_select 'a[href=?][data-turbo-frame=_top]', edit_fiction_path(@fiction, anchor: 'fiction_expected_chapters')
  end

  test 'edit page soft asks for an expected plan' do
    get edit_fiction_url(@fiction)

    assert_match 'Знаєте, скільки розділів буде?', response.body
    assert_select '#fiction_expected_chapters'
    assert_select 'a[href=?]', '#fiction_expected_chapters'
  end

  test 'edit page keeps soft-ask dismiss outside the fiction form' do
    get edit_fiction_url(@fiction)

    assert_select 'form form', false, 'nested forms break CSRF and submit to fictions#update'
    assert_select 'form[action=?]', dismiss_fiction_listing_nudge_path(@fiction)
  end

  test 'dismiss stores the skipped soft ask' do
    post dismiss_fiction_listing_nudge_url(@fiction)

    assert_redirected_to reading_path(@fiction)
    assert_equal Catalog::ListingNudge::OPTIONAL_EXPECTED_AFTER,
                 @fiction.reload.listing_nudge_dismissals['optional_expected']
    assert_nil @fiction.expected_chapters
  end
end
