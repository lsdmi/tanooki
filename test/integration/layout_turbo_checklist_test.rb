# frozen_string_literal: true

require 'test_helper'

class LayoutTurboChecklistTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'static page layout includes turbo morph and view-transition meta tags' do
    get privacy_path

    assert_response :success
    assert_select 'meta[name="turbo-refresh-method"][content="morph"]'
    assert_select 'meta[name="view-transition"][content="same-origin"]'
  end

  test 'static page layout keeps cookie banner and background persistent' do
    get privacy_path

    assert_select '#cookie-consent-banner[data-turbo-permanent]'
    assert_select '#page-background'
    assert_match(%r{/assets/bg-\w+\.webp}, response.body)
  end

  test 'static page layout uses flash turbo frames without legacy modal background' do
    get privacy_path

    assert_no_match(/modal-bg/, response.body)
    assert_select 'turbo-frame#application-notice'
    assert_select 'turbo-frame#application-alert'
  end

  test 'static page layout defers flatpickr and tracks core assets for reload' do
    get privacy_path

    assert_select 'link[href*="flatpickr"]', count: 0
    assert_select 'link[data-turbo-track="reload"]'
  end

  test 'chapter form loads flatpickr without turbo-track' do
    fiction = fictions(:one)
    sign_in users(:user_one)

    get new_chapter_url(fiction: fiction.slug)

    assert_response :success
    assert_select 'link[href*="cdn.jsdelivr.net/npm/flatpickr"]'
    assert_select 'link[href*="cdn.jsdelivr.net/npm/flatpickr"][data-turbo-track]', count: 0
  end
end
