# frozen_string_literal: true

require 'test_helper'

class TalesHelperTest < ActionView::TestCase
  include TalesHelper

  test 'header_picker returns correct class for size greater than or equal to 75' do
    assert_equal 'h-80', header_picker(75)
  end

  test 'header_picker returns correct class for size between 50 and 74' do
    assert_equal 'h-72', header_picker(50)
  end

  test 'header_picker returns correct class for size between 25 and 49' do
    assert_equal 'h-64', header_picker(25)
  end

  test 'header_picker returns correct class for size less than 25' do
    assert_equal 'h-60', header_picker(0)
  end
end
