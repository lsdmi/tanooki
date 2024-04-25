# frozen_string_literal: true

require 'test_helper'

class ChaptersHelperTest < ActionView::TestCase
  include ChaptersHelper

  test "volume_number_integer returns 'NA' when nil is passed" do
    assert_equal 'NA', volume_number_integer(nil)
  end

  test "volume_number_integer returns 0 when 0 is passed" do
    assert_equal 0, volume_number_integer(0)
  end

  test "volume_number_integer returns the correct value when a number is passed" do
    assert_equal 500, volume_number_integer(5)
    assert_equal 0, volume_number_integer(0.0)
    assert_equal 100, volume_number_integer(1)
  end
end
