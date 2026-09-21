# frozen_string_literal: true

require 'test_helper'

class FictionsIndexLcpTest < ActionDispatch::IntegrationTest
  setup do
    @fiction = fictions(:one)
    @fiction.update!(short_description: 'A' * 100)
  end

  test 'index preloads showcase banner with fetchpriority high' do
    visit_fictions_index_with_showcase

    assert_response :success
    assert_select 'link[rel="preload"][as="image"][fetchpriority="high"]'
    assert_select 'img[fetchpriority="high"][loading="eager"]'
  end

  test 'index preloads mobile and desktop showcase banners by media' do
    visit_fictions_index_with_showcase

    assert_select 'link[rel="preload"][as="image"][fetchpriority="high"][media="(max-width: 767px)"]'
    assert_select 'link[rel="preload"][as="image"][fetchpriority="high"][media="(min-width: 768px)"]'
  end

  test 'index first showcase slide uses a mobile picture fallback' do
    visit_fictions_index_with_showcase

    assert_select 'picture source[media="(min-width: 768px)"]'
    assert_select 'img[fetchpriority="high"][loading="eager"][width="768"][height="320"]'
  end

  test 'index places showcase preload before tailwind stylesheet' do
    visit_fictions_index_with_showcase

    assert_operator response.body.index('rel="preload"'), :<, response.body.index('tailwind')
  end

  test 'index omits sweetalert CSS until studio needs it' do
    visit_fictions_index_with_showcase

    assert_select 'link[href*="sweetal2"]', count: 0
  end

  test 'index showcase prefetches only the visible hero chapter CTA' do
    visit_fictions_index_with_showcase

    assert_select 'a[data-turbo-preload="true"][href*="/chapters/"]', count: 1
  end

  test 'index later showcase slides lazy-load a mobile banner variant' do
    visit_fictions_index_with_showcase(slide_count: 2)

    assert_select '[data-controller="custom-carousel"] [data-controller="lazy-bg"]', minimum: 1
    assert_select '[data-controller="custom-carousel"] [data-lazy-bg-small-url-value]', minimum: 1
    assert_select '[data-controller="custom-carousel"] img[fetchpriority="high"]', count: 1
  end

  test 'index does not eager-load hidden search modal posters' do
    visit_fictions_index_with_showcase

    assert_select '#ecommerce-search-modal img[loading="eager"]', count: 0
  end

  private

  def visit_fictions_index_with_showcase(slide_count: 1)
    records = Fiction.where(id: @fiction.id).includes(:fiction_ratings, :banner_attachment).to_a
    records *= slide_count if slide_count > 1

    Fictions::IndexVariablesManager.stub(:showcase, records) do
      get fictions_path
    end
  end
end
