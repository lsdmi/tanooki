# frozen_string_literal: true

require 'test_helper'

class ChaptersControllerReadingProgressTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:user_one)
    @progress = reading_progresses(:one)
    @progress.update!(chapter: chapters(:one))
  end

  test 'show records reading progress for a real visit' do
    get chapter_url(chapters(:two))

    assert_response :success
    assert_equal chapters(:two).id, @progress.reload.chapter_id
  end

  test 'show does not advance reading progress on Turbo prefetch' do
    get chapter_url(chapters(:two)), headers: { 'X-Sec-Purpose' => 'prefetch' }

    assert_response :success
    assert_equal chapters(:one).id, @progress.reload.chapter_id
  end
end
