# frozen_string_literal: true

require 'test_helper'

class SitemapsControllerTest < ActionDispatch::IntegrationTest
  test 'GET sitemap.xml succeeds with XML media type' do
    get '/sitemap.xml'

    assert_response :success
    assert_includes response.media_type, 'xml'
  end

  test 'GET sitemap.xml includes urlset and core hub URLs' do
    get '/sitemap.xml'

    assert_includes response.body, 'xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"'
    assert_includes response.body, 'http://example.com/'
    assert_includes response.body, 'http://example.com/fictions'
  end
end
