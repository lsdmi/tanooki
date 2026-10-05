# frozen_string_literal: true

require 'test_helper'

module Fictions
  class ChapterJumpTest < ActiveSupport::TestCase
    Row = Struct.new(:number, :volume_number)

    def jump(query, rows:, order: :asc)
      ordered = order == :asc ? rows : rows.reverse
      keys = ordered.map { |row| Chapters::ListSectionIndex.section_key_for(row) }.uniq
      grouped = ordered.group_by { |row| Chapters::ListSectionIndex.section_key_for(row) }
      ChapterJump.new(listed: rows.reverse, sections: keys.map { |key| { section_key: key } }, query:,
                      section_rows: ->(section) { grouped.fetch(section[:section_key]) }).call
    end

    def range(first, last) = (first..last).map { |number| Row.new(BigDecimal(number), nil) }

    test 'the window has nine rows above the chapter' do
      result = jump('150', rows: range(1, 200))

      assert_equal 'r-101-200', result.section[:section_key]
      assert_equal [141, 150], [result.window.first.number, result.window[result.target_index].number]
      assert_equal 140, result.rows_above.last.number
    end

    test 'the window stays inside the group at its edges' do
      head = jump('2', rows: range(1, 100))
      tail = jump('99', rows: range(1, 100))

      assert_equal [0, 1], [head.window_start, head.target_index]
      assert_equal [80, 18], [tail.window_start, tail.target_index]
    end

    test 'the field accepts a hash, a decimal comma and spaces' do
      rows = range(1, 10) + [Row.new(BigDecimal('5.5'), nil)]

      assert_equal BigDecimal('5.5'), jump(' #5,5 ', rows:).number
      assert_equal :invalid, jump('abc', rows:).error
      assert_equal :missing, jump('11', rows:).error
    end

    test 'a number repeated across volumes opens the group shown first in the current order' do
      rows = [Row.new(BigDecimal(1), 1.0), Row.new(BigDecimal(1), 2.0)]

      assert_equal 'v-1.0', jump('1', rows:).section[:section_key]
      assert_equal 'v-2.0', jump('1', rows:, order: :desc).section[:section_key]
    end
  end
end
