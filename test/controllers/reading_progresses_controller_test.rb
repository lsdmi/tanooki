# frozen_string_literal: true

require 'test_helper'

class ReadingProgressesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:user_one)
    @fiction = fictions(:one)
    @chapter = chapters(:one)
    sign_in @user
  end

  test 'should update reading status when reading progress exists' do
    reading_progress = ReadingProgress.find_by(fiction: @fiction, user: @user)
    reading_progress.update!(status: :active)

    patch update_status_fiction_reading_progress_path(@fiction), params: { status: :finished }

    assert_response :success
    reading_progress.reload
    assert_equal 'finished', reading_progress.status
  end

  test 'should create reading progress when none exists' do
    user_without_progress = users(:user_two)
    fiction_without_progress = fictions(:two)
    sign_in user_without_progress

    assert_difference('ReadingProgress.count', 1) do
      patch update_status_fiction_reading_progress_path(fiction_without_progress), params: { status: :active }
    end

    assert_response :success
    reading_progress = ReadingProgress.find_by(fiction: fiction_without_progress, user: user_without_progress)
    assert_equal 'active', reading_progress.status
    assert_equal chapters(:three), reading_progress.chapter
  end

  test 'should require authentication' do
    sign_out @user
    patch update_status_fiction_reading_progress_path(@fiction), params: { status: :active }
    assert_redirected_to new_user_session_path
  end
end
