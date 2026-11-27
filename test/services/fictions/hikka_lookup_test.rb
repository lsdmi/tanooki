# frozen_string_literal: true

require 'test_helper'

module Fictions
  class HikkaLookupTest < ActiveSupport::TestCase
    FakeResponse = Struct.new(:code)

    test 'builds the novel endpoint from the slug' do
      assert_equal 'https://api.hikka.io/novel/guimi-zhi-zhu-7059fd', HikkaLookup.new('guimi-zhi-zhu-7059fd').url
    end

    test 'a 200 means the novel exists' do
      assert_equal :found, lookup_with_response('200')
    end

    test 'only a 404 means the novel does not exist' do
      assert_equal :not_found, lookup_with_response('404')
    end

    test 'other statuses are unavailable, including Hikka rate limits' do
      assert_equal :unavailable, lookup_with_response('403')
      assert_equal :unavailable, lookup_with_response('500')
    end

    test 'timeouts and network failures are unavailable' do
      [Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNREFUSED, OpenSSL::SSL::SSLError].each do |error|
        assert_equal :unavailable, lookup_raising(error), "#{error} should be unavailable"
      end
    end

    test 'requests Hikka over TLS with a short timeout' do
      captured = {}
      Net::HTTP.stub(:start, lambda { |*args, **kwargs|
        captured = { args:, kwargs: }
        FakeResponse.new('200')
      }) do
        HikkaLookup.new('abc').call
      end

      assert_equal ['api.hikka.io', 443, HikkaLookup::CONNECTION], [*captured[:args], captured[:kwargs]]
    end

    private

    def lookup_with_response(code)
      Net::HTTP.stub(:start, ->(*, **) { FakeResponse.new(code) }) do
        HikkaLookup.new('abc').call
      end
    end

    def lookup_raising(error_class)
      Net::HTTP.stub(:start, ->(*, **) { raise error_class, 'boom' }) do
        HikkaLookup.new('abc').call
      end
    end
  end
end
