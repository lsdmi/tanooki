# frozen_string_literal: true

require 'test_helper'

class FictionsGuestIndexCacheTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  GUEST_HTTP_MAX_AGE = Fictions::ShowCacheHelper::GUEST_HTTP_EXPIRY.to_i
  GUEST_CACHE_MAX_AGE_PATTERN = /\bmax-age=#{GUEST_HTTP_MAX_AGE}\b/o
  GUEST_PRIVATE_CACHE_CONTROL_PATTERN = /
    (?=.*\bprivate\b)
    (?=.*\bmax-age=#{GUEST_HTTP_MAX_AGE}\b)
    (?=.*\bmust-revalidate\b)
  /xo

  test 'guest fictions index sets private cache-control headers' do
    get fictions_path

    assert_response :success
    assert_match(GUEST_PRIVATE_CACHE_CONTROL_PATTERN, response.headers['Cache-Control'])
  end

  test 'signed in fictions index omits guest cache-control max-age' do
    sign_in users(:user_one)

    get fictions_path

    assert_response :success
    assert_no_match(GUEST_CACHE_MAX_AGE_PATTERN, response.headers['Cache-Control'].to_s)
  end

  test 'guest fictions index returns not modified when etag matches' do
    get fictions_path

    assert_response :success

    etag = response.headers['ETag']

    assert_predicate etag, :present?

    get fictions_path, headers: { 'HTTP_IF_NONE_MATCH' => etag }

    assert_response :not_modified
  end

  test 'guest fictions index skips wild catch overlay' do
    Pokemons::WildCatch.stub(:new, ->(*) { raise 'wild catch should be skipped on fictions#index' }) do
      get fictions_path
    end

    assert_response :success
    assert_nil assigns(:wild_pokemon)
    assert_select 'turbo-frame#catch-pokemon', count: 0
  end

  test 'warm guest index reads showcase latest updates and most reads from cache' do
    Fictions::IndexCacheWarmer.call

    hits = Fictions::IndexVariablesManager.cache_hit_snapshot.fetch_values(
      :showcase, :latest_updates, :most_reads, :popular_novelty, :featured_chapter_count
    )

    assert_predicate hits, :all?

    generated = []
    subscriber = ActiveSupport::Notifications.subscribe('cache_generate.active_support') do |*args|
      generated << ActiveSupport::Notifications::Event.new(*args).payload[:key].to_s
    end

    get fictions_path

    assert_response :success
    leaked = generated.grep(/fiction_showcase_ids|latest_updates_ids|most_reads_ids|popular_novelty/)

    assert_empty leaked, leaked.inspect
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
  end

  test 'guest index logs duration and cache hits' do
    logged = nil
    Rails.logger.stub(:info, lambda { |message = nil, *_args, **_kwargs|
      logged = message if message.to_s.start_with?('[fictions.index]')
    }) do
      get fictions_path
    end

    assert_match(
      /\[fictions.index\] duration_ms=\d+ status=\d+ cache=\S*showcase:(?:hit|miss)/,
      logged.to_s
    )
  end
end
