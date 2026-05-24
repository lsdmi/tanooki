# frozen_string_literal: true

require 'test_helper'

class FictionListFilterParamsTest < ActiveSupport::TestCase
  test 'permit_for_query ignores page param in query hash' do
    params = ActionController::Parameters.new(page: '2', genre: '3', only_new: '1')
    hash = FictionListFilterParams.permit_for_query(params)

    assert_not hash.key?(:page)
    assert_not hash.key?('page')
    assert_equal '3', hash[:genre]
    assert_equal '1', hash[:only_new]
  end

  test 'permit_for_pagy ignores page param in pagy hash' do
    params = ActionController::Parameters.new(page: '2', top_rated: '1')
    hash = FictionListFilterParams.permit_for_pagy(params)

    assert_not hash.key?(:page)
    assert_equal '1', hash[:top_rated]
  end
end
