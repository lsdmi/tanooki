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
    assert_library_history_preloaded(assigns(:history))
  end

  private

  def assert_library_history_preloaded(history)
    assert_not_nil history
    assert_kind_of ActiveRecord::Relation, history

    history.each { |reading| assert_reading_graph_loaded(reading) }
  end

  def assert_reading_graph_loaded(reading)
    assert_not_nil reading.fiction
    assert_not_nil reading.chapter

    assert_not_nil reading.fiction.cover_attachment
    assert_not_nil reading.fiction.cover_attachment.blob

    assert_not_nil reading.fiction.genres
  end
end
