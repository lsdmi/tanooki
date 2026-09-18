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

  test 'static page layout omits theme document.write bootstrap' do
    get privacy_path

    assert_no_match(/document\.write/, response.body)
  end

  test 'static page layout keeps cookie banner and background persistent' do
    get privacy_path

    assert_select '#cookie-consent-banner[data-turbo-permanent]'
    assert_select '#page-background'
    assert_match(%r{/assets/bg-\w+\.webp}, response.body)
  end

  test 'static page layout does not prefetch page background as an img' do
    get privacy_path

    assert_select '#page-background img', count: 0
  end

  test 'static page layout loads compressed theme logos' do
    get privacy_path

    assert_select '#site-logo[src*="logo-default"][src*=".webp"]'
    assert_select '#site-logo[src*="logo-dark"]', count: 0
    assert_select 'footer img[src*="logo-dark"][src*=".webp"]'
  end

  test 'static page layout omits svg logos' do
    get privacy_path

    assert_select 'img[src*="logo"][src*=".svg"]', count: 0
  end

  test 'static page layout uses hidden flash turbo frames' do
    get privacy_path

    assert_no_match(/modal-bg/, response.body)
    assert_select 'turbo-frame#application-notice.hidden'
    assert_select 'turbo-frame#application-alert.hidden'
  end

  test 'static page layout omits flash banner markup' do
    get privacy_path

    assert_select '#toast-default', count: 0
    assert_select '#toast-warning', count: 0
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

  test 'chapter reader skips mode toggler script tag' do
    sign_in users(:user_one)
    chapter = chapters(:one)

    get chapter_url(chapter)

    assert_response :success
    assert_no_match(/import "mode_toggler"/, response.body)
  end

  test 'static page loads mode toggler script tag' do
    get privacy_path

    assert_response :success
    assert_match(/import "mode_toggler"/, response.body)
  end
end
