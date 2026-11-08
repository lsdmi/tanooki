# frozen_string_literal: true

require 'test_helper'

module Chapters
  class FormattingTest < ActiveSupport::TestCase
    test 'format_decimal strips trailing zero fractional part' do
      assert_equal 2, Formatting.format_decimal(2.0)
      assert_in_delta 2.5, Formatting.format_decimal(2.5)
    end

    test 'range bounds floor to whole chapters and keep a prologue below 1' do
      assert_equal 4, Formatting.range_bound(BigDecimal('4.1'))
      assert_equal 57, Formatting.range_bound(BigDecimal('57.2'))
      assert_in_delta 0.5, Formatting.range_bound(BigDecimal('0.5'))
    end

    test 'a number span floors its bounds and collapses one whole chapter' do
      assert_equal '4–57', Formatting.number_span(BigDecimal('4.1'), BigDecimal('57.2'))
      assert_equal '4', Formatting.number_span(BigDecimal('4.1'), BigDecimal('4.9'))
      assert_equal '0.5–1', Formatting.number_span(BigDecimal('0.5'), BigDecimal('1.2'))
    end

    test 'chapter_ref skips blank or zero volumes' do
      assert_equal '9', Formatting.chapter_ref(Chapter.new(number: 9))
      assert_equal '9', Formatting.chapter_ref(Chapter.new(number: 9, volume_number: 0))
    end

    test 'chapter_ref prefixes a positive volume' do
      assert_equal 'Том 2 · 9', Formatting.chapter_ref(Chapter.new(number: 9, volume_number: 2))
      assert_equal 'Том 1.5 · 3', Formatting.chapter_ref(Chapter.new(number: 3, volume_number: BigDecimal('1.5')))
    end
  end
end
