# frozen_string_literal: true

require 'test_helper'

class ChaptersControllerPublishTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @chapter = chapters(:one)
  end

  test 'guest is redirected to fiction when chapter is not yet public' do
    sign_out users(:user_one)
    @chapter.published_at = 1.day.from_now
    @chapter.save(validate: false)
    get chapter_url(@chapter)

    assert_redirected_to fiction_path(@chapter.fiction)
  ensure
    @chapter.published_at = nil
    @chapter.save(validate: false)
  end

  test 'signed in admin can view chapter before public time' do
    sign_in users(:user_one)
    @chapter.published_at = 1.day.from_now
    @chapter.save(validate: false)
    get chapter_url(@chapter)

    assert_response :success
  ensure
    @chapter.published_at = nil
    @chapter.save(validate: false)
  end

  test 'signed in user without scanlator on chapter is redirected when not yet public' do
    sign_out users(:user_one)
    sign_in users(:user_two)
    @chapter.published_at = 1.day.from_now
    @chapter.save(validate: false)
    get chapter_url(@chapter)

    assert_redirected_to fiction_path(@chapter.fiction)
  ensure
    @chapter.published_at = nil
    @chapter.save(validate: false)
  end
end
