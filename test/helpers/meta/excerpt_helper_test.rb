# frozen_string_literal: true

require 'test_helper'

module Meta
  class ExcerptHelperTest < ActionView::TestCase
    tests ExcerptHelper

    test 'first_sentence returns first sentence when delimited' do
      text = 'First sentence. Second sentence.'

      assert_equal 'First sentence.', first_sentence(text)
    end

    test 'first_sentence returns whole string when no sentence end' do
      text = 'No ending punctuation here'

      assert_equal text, first_sentence(text)
    end

    test 'first_sentence handles question and exclamation marks' do
      text = 'Really? Yes! And more.'

      assert_equal 'Really?', first_sentence(text)
    end

    test 'first_sentence returns empty string for blank input' do
      assert_equal '', first_sentence('')
      assert_equal '', first_sentence(nil)
    end
  end
end
