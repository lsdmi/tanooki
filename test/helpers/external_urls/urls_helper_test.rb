# frozen_string_literal: true

require 'test_helper'

module ExternalUrls
  class UrlsHelperTest < ActionView::TestCase
    tests UrlsHelper

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

    test 'linkify_urls returns nil for blank input' do
      assert_nil view.linkify_urls(nil)
      assert_nil view.linkify_urls('')
    end

    test 'linkify_urls wraps https URL with href and target' do
      html = view.linkify_urls('See https://example.com/path here')

      assert_includes html, 'href="https://example.com/path"'
      assert_includes html, 'target="_blank"'
    end

    test 'linkify_urls wraps https URL with rel and default class' do
      html = view.linkify_urls('https://example.com/path')

      assert_includes html, 'rel="noopener noreferrer"'
      assert_includes html, UrlsHelper::DEFAULT_LINKIFY_LINK_CLASS
    end

    test 'linkify_urls uses custom link_class when given' do
      html = view.linkify_urls('https://example.com', link_class: 'custom-link')

      assert_includes html, 'class="custom-link"'
    end

    test 'linkify_urls escapes HTML in non-URL segments' do
      html = view.linkify_urls('<script>x</script>')

      assert_not_includes html, '<script>'
      assert_includes html, '&lt;script&gt;'
    end

    test 'linkify_urls does not wrap URLs without a host' do
      html = view.linkify_urls('broken http:// text')

      assert_not_includes html, 'href='
    end
  end
end
