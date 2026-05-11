# frozen_string_literal: true

require 'test_helper'

class LinkifyHelperTest < ActionView::TestCase
  tests LinkifyHelper

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
    assert_includes html, LinkifyHelper::DEFAULT_LINKIFY_LINK_CLASS
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

    assert_not_includes html, '<a '
  end
end
