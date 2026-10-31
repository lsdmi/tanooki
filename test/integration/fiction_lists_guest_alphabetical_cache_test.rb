# frozen_string_literal: true

require 'test_helper'

class FictionListsGuestAlphabeticalCacheTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  GUEST_HTTP_MAX_AGE = Fictions::ShowCacheHelper::GUEST_HTTP_EXPIRY.to_i
  GUEST_CACHE_MAX_AGE_PATTERN = /\bmax-age=#{GUEST_HTTP_MAX_AGE}\b/o
  GUEST_PRIVATE_CACHE_CONTROL_PATTERN = /
    (?=.*\bprivate\b)
    (?=.*\bmax-age=#{GUEST_HTTP_MAX_AGE}\b)
    (?=.*\bmust-revalidate\b)
  /xo

  test 'guest alphabetical sets private cache-control headers' do
    get alphabetical_fictions_path

    assert_response :success
    assert_match(GUEST_PRIVATE_CACHE_CONTROL_PATTERN, response.headers['Cache-Control'])
  end

  test 'signed in alphabetical omits guest cache-control max-age' do
    sign_in users(:user_one)

    get alphabetical_fictions_path

    assert_response :success
    assert_no_match(GUEST_CACHE_MAX_AGE_PATTERN, response.headers['Cache-Control'].to_s)
  end

  test 'guest alphabetical with filters omits guest max-age' do
    get alphabetical_fictions_path, params: { sort: 'title_asc' }

    assert_response :success
    assert_no_match(GUEST_CACHE_MAX_AGE_PATTERN, response.headers['Cache-Control'].to_s)
  end

  test 'guest alphabetical returns not modified when etag matches' do
    get alphabetical_fictions_path

    assert_response :success
    etag = response.headers['ETag']

    assert_predicate etag, :present?

    get alphabetical_fictions_path, headers: { 'HTTP_IF_NONE_MATCH' => etag }

    assert_response :not_modified
  end

  test 'guest alphabetical skips wild catch overlay' do
    Pokemons::WildCatch.stub(:new, ->(*) { raise 'wild catch should be skipped on guest alphabetical' }) do
      get alphabetical_fictions_path
    end

    assert_response :success
    assert_nil assigns(:wild_encounter_ticket)
  end
end
