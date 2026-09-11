# frozen_string_literal: true

require 'test_helper'

class CatalogListingNudgesAdultContentControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @fiction = fictions(:one)
    @fiction.scanlator_ids = @fiction.scanlators.ids
    @bl = Genre.find_or_create_by!(slug: 'bl') do |genre|
      genre.name = 'БЛ'
      genre.description = 'Тестовий BL-жанр для nudges.'
    end
    @fiction.genres = [@bl]
    @fiction.update!(
      chapter_count: 3,
      expected_chapters: 20,
      completed_at: nil,
      adult_content: false,
      last_chapter_at: 1.day.ago,
      listing_nudge_dismissals: {}
    )
    sign_in users(:user_one)
  end

  test 'readings show asks to mark adult content' do
    get reading_url(@fiction)

    assert_response :success
    assert_match 'У творі є теґи 18+', response.body
    assert_select 'form[action=?]', mark_adult_fiction_listing_nudge_path(@fiction)
  end

  test 'edit page asks to mark adult content' do
    get edit_fiction_url(@fiction)

    assert_response :success
    assert_match 'У творі є теґи 18+', response.body
  end

  test 'edit page keeps adult actions outside the fiction form' do
    get edit_fiction_url(@fiction)

    assert_select 'form form', false, 'nested forms break CSRF and submit to fictions#update'
    assert_select 'form[action=?]', mark_adult_fiction_listing_nudge_path(@fiction)
  end

  test 'mark adult sets the flag' do
    post mark_adult_fiction_listing_nudge_url(@fiction)

    assert_redirected_to reading_path(@fiction)
    assert_predicate @fiction.reload, :adult_content?
  end

  test 'dismiss keeps adult_content false' do
    post dismiss_fiction_listing_nudge_url(@fiction)

    assert_redirected_to reading_path(@fiction)
    assert_equal 'bl', @fiction.reload.listing_nudge_dismissals['adult_content']
    assert_not @fiction.adult_content?
  end

  test 'guest cannot mark adult' do
    sign_out users(:user_one)

    post mark_adult_fiction_listing_nudge_url(@fiction)

    assert_redirected_to new_user_session_path
    assert_not @fiction.reload.adult_content?
  end
end
