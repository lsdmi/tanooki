# frozen_string_literal: true

require 'test_helper'

module Pagination
  class PagyHelperTest < ActionView::TestCase
    include PagyHelper
    include Rails.application.routes.url_helpers

    setup do
      request.path = tales_path
      controller.params = ActionController::Parameters.new
    end

    test 'pagy_url_for is available to all views via ApplicationHelper' do
      assert_respond_to self, :pagy_url_for
    end

    test 'pagy_next_page_src builds next page URL' do
      pagy = Pagy.new(count: 34, page: 1, limit: 17)

      assert_equal "#{tales_path}?page=2", pagy_next_page_src(pagy)
    end
  end
end
