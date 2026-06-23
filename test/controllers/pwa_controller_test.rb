# frozen_string_literal: true

require 'test_helper'

class PwaControllerTest < ActionDispatch::IntegrationTest
  test 'GET manifest returns JSON' do
    get pwa_manifest_path(format: :json)

    assert_response :success
    assert_equal 'application/json', response.media_type
  end

  test 'manifest includes install metadata' do
    get pwa_manifest_path(format: :json)

    manifest = response.parsed_body

    assert_equal 'Бака', manifest['name']
    assert_equal 'standalone', manifest['display']
  end

  test 'manifest references PWA icons' do
    get pwa_manifest_path(format: :json)

    icon_sources = response.parsed_body['icons'].pluck('src')

    assert_includes icon_sources, '/icon-192.png'
    assert_includes icon_sources, '/icon-512.png'
  end

  test 'GET service-worker returns javascript' do
    get pwa_service_worker_path

    assert_response :success
    assert_includes response.media_type, 'javascript'
  end

  test 'service worker caches assets only' do
    get pwa_service_worker_path

    assert_includes response.body, 'CACHE_NAME'
    assert_includes response.body, '/assets/'
  end

  test 'layout includes manifest link' do
    Search::TagCounts.stub(:call, {}) do
      get root_url
    end

    assert_response :success
    assert_select "link[rel='manifest'][href=?]", pwa_manifest_path(format: :json)
  end

  test 'layout includes PWA icon and theme metadata' do
    Search::TagCounts.stub(:call, {}) do
      get root_url
    end

    assert_select "link[rel='apple-touch-icon'][href='/icon-192.png']"
    assert_select "meta[name='theme-color'][content='#78716c']"
  end
end
