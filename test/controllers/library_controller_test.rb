# frozen_string_literal: true

require 'test_helper'

class LibraryControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:user_two)
    sign_in @user
  end

  test 'should get index' do
    get library_url
    assert_response :success
  end

  test 'should fetch history with related associations' do
    get library_url
    assert_response :success

    assert_not_nil assigns(:history)
    assert_kind_of ActiveRecord::Relation, assigns(:history)

    assigns(:history).each do |reading|
      assert_not_nil reading.fiction
      assert_not_nil reading.chapter

      assert_not_nil reading.fiction.cover_attachment
      assert_not_nil reading.fiction.cover_attachment.blob

      assert_not_nil reading.fiction.genres
    end
  end

  test 'should fetch history stats' do
    get library_url
    assert_response :success

    assert_not_nil assigns(:history_stats)
    assert_kind_of Hash, assigns(:history_stats)

    assert_equal Chapter.all.size, assigns(:history_stats)[:total_chapters]
    assert_equal Fiction.all.size, assigns(:history_stats)[:total_fictions]
    assert_equal Chapter.pluck(:views).sum, assigns(:history_stats)[:total_views]
  end

  test 'should fetch popular fictions' do
    Rails.cache.write('popular_fictions_library', 'Cached data')

    get library_url
    assert_response :success

    assert_not_nil assigns(:popular_fictions)
    assert_kind_of ActiveRecord::Relation, assigns(:popular_fictions)
  end
end
