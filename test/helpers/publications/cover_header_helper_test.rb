# frozen_string_literal: true

require 'test_helper'

module Publications
  class CoverHeaderHelperTest < ActionView::TestCase
    tests CoverHeaderHelper

    test 'cover_header_height_class returns h-80 for length 75 and above' do
      assert_equal 'h-80', view.cover_header_height_class(75)
    end

    test 'cover_header_height_class returns h-72 for length 50–74' do
      assert_equal 'h-72', view.cover_header_height_class(50)
    end

    test 'cover_header_height_class returns h-64 for length 25–49' do
      assert_equal 'h-64', view.cover_header_height_class(25)
    end

    test 'cover_header_height_class returns h-60 for length below 25' do
      assert_equal 'h-60', view.cover_header_height_class(0)
    end
  end
end
