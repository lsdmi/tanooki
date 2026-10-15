# frozen_string_literal: true

require 'test_helper'

class ChaptersGuestShowCacheTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  GUEST_HTTP_MAX_AGE = Chapters::GuestShowCaching::GUEST_HTTP_EXPIRY.to_i
  GUEST_CACHE_MAX_AGE_PATTERN = /\bmax-age=#{GUEST_HTTP_MAX_AGE}\b/o
  GUEST_PRIVATE_CACHE_CONTROL_PATTERN = /
    (?=.*\bprivate\b)
    (?=.*\bmax-age=#{GUEST_HTTP_MAX_AGE}\b)
    (?=.*\bmust-revalidate\b)
  /xo

  setup do
    @chapter = chapters(:one)
  end

  test 'guest chapter show sets private cache-control headers' do
    get chapter_path(@chapter)

    assert_response :success
    assert_match(GUEST_PRIVATE_CACHE_CONTROL_PATTERN, response.headers['Cache-Control'])
  end

  test 'guest chapter show varies on cookies' do
    get chapter_path(@chapter)

    assert_includes response.headers['Vary'].split(/,\s*/), 'Cookie'
  end

  test 'signed in chapter show omits guest cache-control max-age' do
    sign_in users(:user_one)

    get chapter_path(@chapter)

    assert_response :success
    assert_no_match(GUEST_CACHE_MAX_AGE_PATTERN, response.headers['Cache-Control'].to_s)
  end
end
