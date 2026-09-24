# frozen_string_literal: true

require 'test_helper'

class CatalogListingNudgesContentRatingControllerTest < ActionDispatch::IntegrationTest
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
      content_rating: :everyone,
      last_chapter_at: 1.day.ago,
      listing_nudge_dismissals: {}
    )
    sign_in users(:user_one)
  end

  test 'readings show asks to set content rating' do
    get reading_url(@fiction)

    assert_response :success
    assert_match 'Це лише підказка', response.body
    assert_select 'form[action=?]', mark_sixteen_fiction_listing_nudge_path(@fiction)
  end

  test 'readings show offers both rating mark actions' do
    get reading_url(@fiction)

    assert_select 'form[action=?]', mark_sixteen_fiction_listing_nudge_path(@fiction)
    assert_select 'form[action=?]', mark_eighteen_fiction_listing_nudge_path(@fiction)
  end

  test 'edit page asks to set content rating' do
    get edit_fiction_url(@fiction)

    assert_response :success
    assert_match 'Це лише підказка', response.body
  end

  test 'edit page keeps rating actions outside the fiction form' do
    get edit_fiction_url(@fiction)

    assert_select 'form form', false, 'nested forms break CSRF and submit to fictions#update'
    assert_select 'form[action=?]', mark_sixteen_fiction_listing_nudge_path(@fiction)
    assert_select 'form[action=?]', mark_eighteen_fiction_listing_nudge_path(@fiction)
  end

  test 'mark sixteen sets content_rating' do
    post mark_sixteen_fiction_listing_nudge_url(@fiction)

    assert_redirected_to reading_path(@fiction)
    assert_predicate @fiction.reload, :content_rating_sixteen?
  end

  test 'mark eighteen sets content_rating' do
    post mark_eighteen_fiction_listing_nudge_url(@fiction)

    assert_redirected_to reading_path(@fiction)
    assert_predicate @fiction.reload, :content_rating_eighteen?
  end

  test 'dismiss keeps content_rating everyone' do
    post dismiss_fiction_listing_nudge_url(@fiction)

    assert_redirected_to reading_path(@fiction)
    assert_equal 'bl', @fiction.reload.listing_nudge_dismissals['content_rating']
    assert_predicate @fiction, :content_rating_everyone?
  end

  test 'guest cannot mark sixteen' do
    sign_out users(:user_one)

    post mark_sixteen_fiction_listing_nudge_url(@fiction)

    assert_redirected_to new_user_session_path
    assert_predicate @fiction.reload, :content_rating_everyone?
  end
end
