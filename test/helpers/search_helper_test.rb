# frozen_string_literal: true

require 'test_helper'

class SearchHelperTest < ActionView::TestCase
  include SearchHelper

  def setup
    @results = (1..10).to_a
  end

  test 'tag_group should calculate the correct size' do
    assert_equal 0, tag_group(5)
    assert_equal 1, tag_group(8)
    assert_equal 2, tag_group(11)
  end

  test 'main_column should return the correct results' do
    assert_equal [7], main_column(@results)
  end

  test 'right_column should return the correct results' do
    assert_equal [8], right_column(@results)
  end

  test 'left_column should return the correct results' do
    assert_equal [6], left_column(@results)
  end

  test 'random_size should return one of the defined sizes' do
    assert_includes ['lg:h-[200px]', 'lg:h-[250px]', 'lg:h-[300px]'], random_size
  end
end
