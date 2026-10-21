# frozen_string_literal: true

require 'test_helper'

module ContentFilters
  class ResolverTest < ActiveSupport::TestCase
    test 'an account is resolved in one query and ignores the guest cookie' do
      queries = sql_queries do
        preference = Resolver.call(user: users(:user_two), cookies: cookie_jar('no18'))

        assert_nil preference.max_rating
        assert_equal [genres(:one).id, genres(:two).id].sort, preference.hidden_genre_ids.sort
      end

      filter_reads = queries.count { |sql| sql.include?('user_content_filters') }

      assert_equal 1, filter_reads
    end

    test 'an account rating cap is read with its genres' do
      preference = Resolver.call(user: users(:user_one), cookies: cookie_jar('no18'))

      assert_equal 16, preference.max_rating
      assert_empty preference.hidden_genre_ids
    end

    test 'a reader with no row stays open' do
      preference = Resolver.call(user: users(:user_one_one_zero), cookies: cookie_jar('no18'))

      assert_equal 'open', preference.fingerprint
    end

    test 'a guest cookie hides 18+' do
      preference = Resolver.call(user: nil, cookies: cookie_jar(Resolver::GUEST_HIDE_EIGHTEEN))

      assert_equal 16, preference.max_rating
      assert_empty preference.hidden_genre_ids
      assert_match(/\Ar16-[0-9a-f]{8}\z/, preference.fingerprint)
    end

    test 'a missing or unknown guest cookie stays open' do
      assert_equal 'open', Resolver.call(user: nil, cookies: cookie_jar(nil)).fingerprint
      assert_equal 'open', Resolver.call(user: nil, cookies: cookie_jar('everything')).fingerprint
      assert_equal 'open', Resolver.call(user: nil, cookies: nil).fingerprint
    end

    test 'a tampered cookie does not sign and stays open' do
      request = ActionDispatch::TestRequest.create
      request.cookie_jar[:content_filter] = Resolver::GUEST_HIDE_EIGHTEEN

      preference = Resolver.call(user: nil, cookies: request.cookie_jar)

      assert_equal 'open', preference.fingerprint
    end

    test 'a signed guest cookie round-trips' do
      request = ActionDispatch::TestRequest.create
      request.cookie_jar.signed[Resolver::COOKIE_KEY] = Resolver::GUEST_HIDE_EIGHTEEN

      preference = Resolver.call(user: nil, cookies: request.cookie_jar)

      assert_equal 16, preference.max_rating
    end

    private

    def cookie_jar(value)
      jar = Object.new
      signed = { Resolver::COOKIE_KEY => value }
      jar.define_singleton_method(:signed) { signed }
      jar
    end

    def sql_queries(&)
      queries = []
      callback = ->(*, payload) { queries << payload[:sql] unless payload[:name] == 'SCHEMA' }
      ActiveSupport::Notifications.subscribed(callback, 'sql.active_record', &)
      queries
    end
  end
end
