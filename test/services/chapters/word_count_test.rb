# frozen_string_literal: true

require 'test_helper'

module Chapters
  class WordCountTest < ActiveSupport::TestCase
    test 'counts letters digits apostrophes and hyphens' do
      assert_equal 4, WordCount.call("п'ять пʼять twenty-one 42")
    end

    test 'ignores emoji and punctuation' do
      assert_equal 2, WordCount.call('Привіт, світ! 👋')
    end

    test 'blank text is zero' do
      assert_equal 0, WordCount.call(nil)
      assert_equal 0, WordCount.call('   ')
    end
  end
end
