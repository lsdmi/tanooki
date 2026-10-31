# frozen_string_literal: true

require 'test_helper'

module Fictions
  class ListPaginationHelperTest < ActionView::TestCase
    include ListPaginationHelper
    include Rails.application.routes.url_helpers

    setup do
      request.path = alphabetical_fictions_path
      controller.params = ActionController::Parameters.new
    end

    test 'fiction_list_pagy_custom_params allows numeric genre and flag keys only' do
      controller.params[:genre] = '12'
      controller.params[:only_new] = '1'
      controller.params[:include_eighteen] = '1'
      controller.params[:evil] = '<script>'

      assert_equal(
        { genre: '12', only_new: '1', include_eighteen: '1' },
        fiction_list_pagy_custom_params
      )
    end

    test 'fiction_list_pagy_custom_params maps legacy adult_content to include_eighteen' do
      controller.params[:adult_content] = '1'

      assert_equal({ include_eighteen: '1' }, fiction_list_pagy_custom_params)
    end

    test 'fiction_list_pagy_custom_params rejects non-numeric genre' do
      controller.params[:genre] = '<img onerror=alert(1)>'

      assert_empty(fiction_list_pagy_custom_params)
    end

    test 'fiction_list_pagy_custom_params keeps a non-default sort' do
      controller.params[:sort] = 'popular_desc'
      controller.params[:view] = 'list'

      assert_equal({ view: 'list', sort: 'popular_desc' }, fiction_list_pagy_custom_params)
    end

    test 'fiction_list_pagy_custom_params omits the default sort' do
      controller.params[:sort] = 'updated_desc'

      assert_empty(fiction_list_pagy_custom_params)
    end

    test 'catalog_mid_ad inserts after twelve items' do
      assert catalog_mid_ad?(index: 11, total: 24)
      assert_not catalog_mid_ad?(index: 10, total: 24)
    end

    test 'catalog_mid_ad inserts at the end when fewer than twelve' do
      assert catalog_mid_ad?(index: 10, total: 11)
      assert catalog_mid_ad?(index: 0, total: 1)
      assert_not catalog_mid_ad?(index: 0, total: 0)
    end
  end
end
