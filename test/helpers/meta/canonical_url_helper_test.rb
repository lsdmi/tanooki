# frozen_string_literal: true

require 'test_helper'

module Meta
  class CanonicalUrlHelperTest < ActionView::TestCase
    include Devise::Test::IntegrationHelpers

    test 'canonical_url omits non-search query params outside production' do
      assign_mock_request('http://example.com/fictions?order=desc&utm_source=x')

      assert_equal 'http://example.com/fictions', canonical_url
    end

    test 'canonical_url uses production host and strips non-search query params in production' do
      assign_mock_request('http://legacy.example/fictions/1?gclid=abc')

      Rails.stub :env, ActiveSupport::StringInquirer.new('production') do
        assert_equal 'https://baka.in.ua/fictions/1', canonical_url
      end
    end

    test 'canonical_url omits query string when search is absent' do
      assign_mock_request('http://example.com/?utm_campaign=spring')

      assert_equal 'http://example.com/', canonical_url
    end

    test 'canonical_url keeps only search on search index' do
      assign_mock_request('http://example.com/search?search[]=test&filter=blog&page=2')

      assert_equal 'http://example.com/search?search%5B%5D=test', canonical_url
    end

    test 'canonical_url drops fiction list filter params' do
      assign_mock_request('http://example.com/fictions/alphabetical?genre=3&adult_content=1&only_new=1')

      assert_equal 'http://example.com/fictions/alphabetical', canonical_url
    end

    test 'canonical_url drops chapter calendar subscriptions param' do
      assign_mock_request('http://example.com/fictions/calendar?subscriptions=1')

      assert_equal 'http://example.com/fictions/calendar', canonical_url
    end

    private

    def assign_mock_request(url)
      req = ActionDispatch::Request.new(Rack::MockRequest.env_for(url))
      @controller.request = req
      @request = req
    end
  end
end
