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
      controller.params[:evil] = '<script>'

      assert_equal({ genre: '12', only_new: '1' }, fiction_list_pagy_custom_params)
    end

    test 'fiction_list_pagy_custom_params rejects non-numeric genre' do
      controller.params[:genre] = '<img onerror=alert(1)>'

      assert_empty(fiction_list_pagy_custom_params)
    end
  end
end
