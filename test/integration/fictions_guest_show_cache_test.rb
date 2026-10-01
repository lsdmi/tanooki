# frozen_string_literal: true

require 'test_helper'

class FictionsGuestShowCacheTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  GUEST_HTTP_MAX_AGE = Fictions::ShowCacheHelper::GUEST_HTTP_EXPIRY.to_i
  GUEST_CACHE_MAX_AGE_PATTERN = /\bmax-age=#{GUEST_HTTP_MAX_AGE}\b/o
  TURBO_FORM_REDIRECT_HEADERS = { 'Accept' => 'text/vnd.turbo-stream.html, text/html, application/xhtml+xml' }.freeze
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

  test 'guest fiction show varies on cookies so signing in skips the cached guest page' do
    get fiction_path(fictions(:one))

    assert_includes response.headers['Vary'].split(/,\s*/), 'Cookie'
  end

  test 'signed in fiction show omits guest cache-control max-age' do
    sign_in users(:user_one)

    get fiction_path(fictions(:one))

    assert_response :success

    cache_control = response.headers['Cache-Control'].to_s

    assert_no_match(GUEST_CACHE_MAX_AGE_PATTERN, cache_control)
  end

  # A Turbo form submission that redirects here (sign-in with return_to) asks for turbo streams first.
  test 'turbo form redirect gets the page' do
    get fiction_path(fictions(:one)), headers: TURBO_FORM_REDIRECT_HEADERS

    assert_response :success
    assert_equal 'text/html', response.media_type
    assert_select 'h1#fiction-title'
  end

  test 'turbo form redirect stays outside the guest browser cache' do
    get fiction_path(fictions(:one)), headers: TURBO_FORM_REDIRECT_HEADERS

    assert_no_match(GUEST_CACHE_MAX_AGE_PATTERN, response.headers['Cache-Control'].to_s)
  end

  test 'guest fiction show still renders page content' do
    get fiction_path(fictions(:one))

    assert_response :success
    assert_select 'turbo-frame#fiction_comments[loading=lazy]'
    assert_select '[data-controller="chapters-accordion"]'
  end
end
