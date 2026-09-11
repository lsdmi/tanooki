# frozen_string_literal: true

require 'test_helper'

class CatalogListingNudgesMissingGenresControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @fiction = fictions(:one)
    @fiction.scanlator_ids = @fiction.scanlators.ids
    @fiction.genres = []
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

  test 'readings show asks to add a genre' do
    get reading_url(@fiction)

    assert_response :success
    assert_match 'Додайте хоча б один жанр', response.body
    assert_select 'a[href=?][data-turbo-frame=_top]', edit_fiction_path(@fiction, anchor: 'fiction_genre_ids')
  end

  test 'edit page asks to add a genre' do
    get edit_fiction_url(@fiction)

    assert_match 'Додайте хоча б один жанр', response.body
    assert_select '#fiction_genre_ids'
    assert_select 'a[href=?]', '#fiction_genre_ids'
  end

  test 'edit page keeps missing-genres dismiss outside the fiction form' do
    get edit_fiction_url(@fiction)

    assert_select 'form form', false, 'nested forms break CSRF and submit to fictions#update'
    assert_select 'form[action=?]', dismiss_fiction_listing_nudge_path(@fiction)
  end

  test 'dismiss stores the skipped missing-genres ask' do
    post dismiss_fiction_listing_nudge_url(@fiction)

    assert_redirected_to reading_path(@fiction)
    assert_equal 3, @fiction.reload.listing_nudge_dismissals['missing_genres']
    assert_empty @fiction.genres
  end
end
