# frozen_string_literal: true

require 'test_helper'

class MorphHeadParityTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'homepage omits unused feature stylesheets' do
    Search::TagCounts.stub(:call, {}) { get root_path }
    hrefs = tracked_stylesheet_hrefs(response.body).join(' ')

    assert_no_match(/pagy|slimselect|sweetal2/, hrefs)
  end

  test 'homepage omits reader and actiontext stylesheets' do
    Search::TagCounts.stub(:call, {}) { get root_path }
    hrefs = tracked_stylesheet_hrefs(response.body).join(' ')

    assert_no_match(/chapters_reader|actiontext/, hrefs)
  end

  test 'studio index tracks sweetalert stylesheet for turbo reload' do
    sign_in users(:user_one)
    get studio_index_path

    assert_select 'link[href*="sweetal2"][data-turbo-track="reload"]'
  end

  test 'chapter reader tracks reader and actiontext stylesheets' do
    get chapter_url(chapters(:one))

    assert_select 'link[href*="chapters_reader"][data-turbo-track="reload"]'
    assert_select 'link[href*="actiontext"][data-turbo-track="reload"]'
  end

  test 'browse routes include turbo morph meta tag' do
    get fictions_path

    assert_select 'meta[name="turbo-refresh-method"][content="morph"]'
  end

  test 'chapter form tracked stylesheets include slimselect and flatpickr overrides' do
    sign_in users(:user_one)
    get new_chapter_url(fiction: fictions(:one).slug)
    form_hrefs = tracked_stylesheet_hrefs(response.body)

    Search::TagCounts.stub(:call, {}) { get root_path }
    browse_hrefs = tracked_stylesheet_hrefs(response.body)
    extra = (form_hrefs - browse_hrefs).join(' ')

    assert_includes extra, 'flatpickr_overrides'
    assert_includes extra, 'slimselect'
  end
end
