# frozen_string_literal: true

require 'test_helper'

module Bookshelves
  class FictionSearchTest < ActiveSupport::TestCase
    test 'returns browse list for blank query' do
      assert_predicate FictionSearch.call(query: ''), :any?
    end

    test 'returns matching fiction options' do
      fiction = fictions(:one)
      options = FictionSearch.call(query: fiction.title.first(3))

      assert(options.any? { |option| option[:value] == fiction.id.to_s })
      assert_equal fiction.title, options.find { |option| option[:value] == fiction.id.to_s }[:text]
    end
  end
end
