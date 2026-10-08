# frozen_string_literal: true

require 'test_helper'

module Fictions
  class ExactTitleMatchTest < ActiveSupport::TestCase
    test 'matches a normalized title and ignores a soft-deleted fiction' do
      assert_equal [fictions(:one).id], ExactTitleMatch.new(title: 'test fiction!', english_title: nil).call.map(&:id)

      fictions(:one).destroy!

      assert_empty ExactTitleMatch.new(title: 'Test Fiction', english_title: nil).call
    end

    test 'matches an english title and an alternative title' do
      fiction = fictions(:two)
      fiction.english_title = 'Shared English'
      fiction.alternative_title = 'Прихована назва'
      fiction.save!(validate: false)

      by_english = ExactTitleMatch.new(title: 'Інше', english_title: 'shared-english').call
      by_alternative = ExactTitleMatch.new(title: 'прихована назва', english_title: '').call

      assert_equal [fiction.id], by_english.map(&:id)
      assert_equal [fiction.id], by_alternative.map(&:id)
    end

    test 'returns nothing for a blank title' do
      assert_empty ExactTitleMatch.new(title: '—', english_title: nil).call
    end
  end
end
