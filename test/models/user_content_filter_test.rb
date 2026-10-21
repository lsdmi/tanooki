# frozen_string_literal: true

require 'test_helper'

class UserContentFilterTest < ActiveSupport::TestCase
  test 'allows no cap, hide 18+, or hide 16+ and 18+' do
    user = users(:user_one_one_zero)

    [nil, 0, 16].each do |rating|
      filter = UserContentFilter.new(user:, max_content_rating: rating)

      assert_predicate filter, :valid?, rating.inspect
    end
  end

  test 'rejects a cap that is not a list band' do
    filter = UserContentFilter.new(user: users(:user_one_one_zero), max_content_rating: 18)

    assert_not filter.valid?
    assert filter.errors.of_kind?(:max_content_rating, :inclusion)
  end

  test 'one row per account' do
    duplicate = UserContentFilter.new(user: users(:user_one), max_content_rating: 0)

    assert_raises(ActiveRecord::RecordNotUnique) { duplicate.save!(validate: false) }
  end
end
