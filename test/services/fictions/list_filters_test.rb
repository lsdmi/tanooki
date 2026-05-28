# frozen_string_literal: true

require 'test_helper'

module Fictions
  class ListFiltersTest < ActiveSupport::TestCase
    test 'permit_for_query ignores page param in query hash' do
      params = ActionController::Parameters.new(page: '2', genre: '3', only_new: '1')
      hash = ListFilters.permit_for_query(params)

      assert_equal({ genre: '3', only_new: '1' }, hash.symbolize_keys)
    end

    test 'permit_for_pagy ignores page param in pagy hash' do
      params = ActionController::Parameters.new(page: '2', top_rated: '1')
      hash = ListFilters.permit_for_pagy(params)

      assert_equal({ top_rated: '1' }, hash)
    end
  end
end
