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

  test 'index places showcase preload before tailwind stylesheet' do
    visit_fictions_index_with_showcase

    assert_operator response.body.index('rel="preload"'), :<, response.body.index('tailwind')
  end

  test 'index omits unused render blocking stylesheets' do
    visit_fictions_index_with_showcase

    assert_select 'link[href*="fonts.googleapis.com"]', count: 0
    assert_select 'link[href*="sweetal2"]', count: 0
  end

  private

  def visit_fictions_index_with_showcase
    showcase = Fiction.where(id: @fiction.id).includes(:fiction_ratings, :banner_attachment)

    Fictions::IndexVariablesManager.stub(:showcase, showcase) do
      get fictions_path
    end
  end
end
