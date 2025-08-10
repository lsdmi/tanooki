# frozen_string_literal: true

require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  test 'punch should return string if first sentence if less than 20 characters' do
    string = 'This is a test. This is only a test.'
    assert_equal string, punch(string)
  end

  test 'punch should return the whole string if there is no sentence end' do
    string = 'This is a test'
    assert_equal string, punch(string)
  end

  test 'punch should handle special characters' do
    string = 'This is a test! And this is another test?'
    assert_equal string, punch(string)
  end

  test 'punch should handle empty strings' do
    string = ''
    assert_equal '', punch(string)
  end
end
