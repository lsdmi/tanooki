# frozen_string_literal: true

require 'test_helper'

class MorphHeadParityTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'fictions index and studio index tracked stylesheets match' do
    sign_in users(:user_one)
    get fictions_path
    fictions_hrefs = tracked_stylesheet_hrefs(response.body)

    get studio_index_path

    assert_equal fictions_hrefs, tracked_stylesheet_hrefs(response.body)
  end

  test 'fiction show and studio index tracked stylesheets match' do
    sign_in users(:user_one)
    fiction = fictions(:one)
    Rails.cache.delete("fiction_#{fiction.id}")

    get fiction_path(fiction)
    fiction_hrefs = tracked_stylesheet_hrefs(response.body)

    get studio_index_path

    assert_equal fiction_hrefs, tracked_stylesheet_hrefs(response.body)
  end

  test 'privacy page and fictions index tracked stylesheets match' do
    get privacy_path
    privacy_hrefs = tracked_stylesheet_hrefs(response.body)

    get fictions_path

    assert_equal privacy_hrefs, tracked_stylesheet_hrefs(response.body)
  end

  test 'browse routes include turbo morph meta tag' do
    get fictions_path

    assert_select 'meta[name="turbo-refresh-method"][content="morph"]'
  end

  test 'chapter form tracked stylesheets differ from browse by flatpickr overrides' do
    sign_in users(:user_one)
    get new_chapter_url(fiction: fictions(:one).slug)
    form_hrefs = tracked_stylesheet_hrefs(response.body)

    get fictions_path
    browse_hrefs = tracked_stylesheet_hrefs(response.body)

    assert_includes (form_hrefs - browse_hrefs).join(' '), 'flatpickr_overrides'
  end
end
