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

    test 'permit_for_pagy writes include_eighteen and drops legacy adult_content' do
      params = ActionController::Parameters.new(adult_content: '1', genre: '3')
      hash = ListFilters.permit_for_pagy(params)

      assert_equal({ genre: '3', include_eighteen: '1' }, hash)
      assert_not hash.key?(:adult_content)
    end

    test 'permit_for_pagy omits include_eighteen when explicitly zero' do
      params = ActionController::Parameters.new(include_eighteen: '0')
      hash = ListFilters.permit_for_pagy(params)

      assert_empty hash
    end

    test 'include_eighteen? is true for new and legacy params' do
      assert ListFilters.include_eighteen?(ActionController::Parameters.new(include_eighteen: '1'))
      assert ListFilters.include_eighteen?(ActionController::Parameters.new(adult_content: '1'))
    end

    test 'include_eighteen? is false when absent or zero' do
      assert_not ListFilters.include_eighteen?(ActionController::Parameters.new)
      assert_not ListFilters.include_eighteen?(ActionController::Parameters.new(include_eighteen: '0'))
    end

    test 'include_eighteen_param_specified? detects key presence' do
      assert ListFilters.include_eighteen_param_specified?(
        ActionController::Parameters.new(include_eighteen: '0')
      )
      assert_not ListFilters.include_eighteen_param_specified?(ActionController::Parameters.new)
    end
  end
end
