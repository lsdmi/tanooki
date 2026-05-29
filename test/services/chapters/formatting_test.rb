# frozen_string_literal: true

require 'test_helper'

module Chapters
  class FormattingTest < ActiveSupport::TestCase
    test 'format_decimal strips trailing zero fractional part' do
      assert_equal 2, Formatting.format_decimal(2.0)
      assert_equal 2.5, Formatting.format_decimal(2.5)
    end
  end
end
