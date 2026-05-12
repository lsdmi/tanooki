# frozen_string_literal: true

require 'test_helper'

module ExternalUrls
  class HttpsHelperTest < ActionView::TestCase
    tests HttpsHelper

    test 'https_url leaves http and https URLs unchanged' do
      assert_equal 'https://a.test', view.https_url('https://a.test')
      assert_equal 'http://b.test', view.https_url('http://b.test')
    end

    test 'https_url prepends https scheme for host-only input' do
      assert_equal 'https://example.com', view.https_url('example.com')
    end

    test 'https_url returns empty string for blank input' do
      assert_equal '', view.https_url(nil)
      assert_equal '', view.https_url('')
    end
  end
end
