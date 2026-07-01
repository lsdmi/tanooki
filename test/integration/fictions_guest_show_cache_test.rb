# frozen_string_literal: true

require 'test_helper'

class FictionsGuestShowCacheTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  GUEST_HTTP_MAX_AGE = Fictions::ShowCacheHelper::GUEST_HTTP_EXPIRY.to_i
  GUEST_CACHE_MAX_AGE_PATTERN = /\bmax-age=#{GUEST_HTTP_MAX_AGE}\b/o
  GUEST_PRIVATE_CACHE_CONTROL_PATTERN = /
    (?=.*\bprivate\b)
    (?=.*\bmax-age=#{GUEST_HTTP_MAX_AGE}\b)
    (?=.*\bmust-revalidate\b)
  /xo

  test 'guest fiction show sets private cache-control headers' do
    get fiction_path(fictions(:one))

    assert_response :success

    cache_control = response.headers['Cache-Control']

    assert_match(GUEST_PRIVATE_CACHE_CONTROL_PATTERN, cache_control)
  end

  test 'signed in fiction show omits guest cache-control max-age' do
    sign_in users(:user_one)

    get fiction_path(fictions(:one))

    assert_response :success

    cache_control = response.headers['Cache-Control'].to_s

    assert_no_match(GUEST_CACHE_MAX_AGE_PATTERN, cache_control)
  end

  test 'guest fiction show turbo stream response omits guest cache-control max-age' do
    get fiction_path(fictions(:one)), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

    assert_response :success

    cache_control = response.headers['Cache-Control'].to_s

    assert_no_match(GUEST_CACHE_MAX_AGE_PATTERN, cache_control)
  end

  test 'guest fiction show still renders page content' do
    get fiction_path(fictions(:one))

    assert_response :success
    assert_select 'turbo-frame#fiction_comments[loading=lazy]'
    assert_select '[data-controller="chapters-accordion"]'
  end
end
