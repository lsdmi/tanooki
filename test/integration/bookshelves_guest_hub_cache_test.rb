# frozen_string_literal: true

require 'test_helper'

class BookshelvesGuestHubCacheTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  GUEST_HTTP_MAX_AGE = Fictions::ShowCacheHelper::GUEST_HTTP_EXPIRY.to_i
  GUEST_CACHE_MAX_AGE_PATTERN = /\bmax-age=#{GUEST_HTTP_MAX_AGE}\b/o
  GUEST_PRIVATE_CACHE_CONTROL_PATTERN = /
    (?=.*\bprivate\b)
    (?=.*\bmax-age=#{GUEST_HTTP_MAX_AGE}\b)
    (?=.*\bmust-revalidate\b)
  /xo

  test 'guest hub sets private cache-control headers' do
    get bookshelves_path

    assert_response :success
    assert_match(GUEST_PRIVATE_CACHE_CONTROL_PATTERN, response.headers['Cache-Control'])
  end

  test 'signed in hub omits guest cache-control max-age' do
    sign_in users(:user_one)

    get bookshelves_path

    assert_response :success
    assert_no_match(GUEST_CACHE_MAX_AGE_PATTERN, response.headers['Cache-Control'].to_s)
  end

  test 'guest hub with page query omits guest max-age' do
    get bookshelves_path, params: { page: 2 }

    assert_response :success
    assert_no_match(GUEST_CACHE_MAX_AGE_PATTERN, response.headers['Cache-Control'].to_s)
  end

  test 'guest hub returns not modified when etag matches' do
    get bookshelves_path

    assert_response :success
    etag = response.headers['ETag']

    assert_predicate etag, :present?

    get bookshelves_path, headers: { 'HTTP_IF_NONE_MATCH' => etag }

    assert_response :not_modified
  end
end
