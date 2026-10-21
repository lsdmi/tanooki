# frozen_string_literal: true

require 'test_helper'

module Users
  class ContentFiltersControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    test 'an account saves a rating cap and three genres' do
      user = users(:user_one)
      sign_in user
      ids = [genres(:one).id, genres(:two).id, genres(:three).id]

      patch content_filter_path, params: { max_content_rating: '0', hidden_genre_ids: ids }, as: :turbo_stream

      assert_response :success
      assert_turbo_stream_flash_notice(I18n.t('content_filters.saved'))
      stored = [user.reload.content_filter.max_content_rating, user.hidden_genres.pluck(:genre_id).sort]

      assert_equal [0, ids.sort], stored
    end

    test 'the profile tab shows the saved choice' do
      user = users(:user_two)
      sign_in user

      get studio_index_path(tab: 'profile')

      assert_response :success
      assert_match(/id="content_filter_rating_all"[^>]*checked/, response.body)
      assert_match(/id="content_filter_genre_#{genres(:one).id}"[^>]*checked/, response.body)
    end

    test 'reset opens the catalogue again' do
      user = users(:user_two)
      sign_in user

      patch content_filter_path, params: { max_content_rating: '' }, as: :turbo_stream

      assert_response :success
      assert_empty user.reload.hidden_genres
      assert_match(/id="content_filter_rating_all"[^>]*checked/, response.body)
    end

    test 'a rejected save keeps the stored filter' do
      user = users(:user_one)
      sign_in user

      patch content_filter_path,
            params: { max_content_rating: '18', hidden_genre_ids: [genres(:one).id] },
            as: :turbo_stream

      assert_response :unprocessable_content
      assert_includes response.body, I18n.t('content_filters.errors.rating')
      assert_equal 16, user.reload.content_filter.max_content_rating
    end

    test 'a guest is sent to sign in' do
      patch content_filter_path, params: { max_content_rating: '16' }

      assert_redirected_to new_user_session_path
    end
  end
end
