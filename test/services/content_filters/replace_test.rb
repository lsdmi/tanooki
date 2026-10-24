# frozen_string_literal: true

require 'test_helper'

module ContentFilters
  class ReplaceTest < ActiveSupport::TestCase
    test 'saves a rating cap and replaces packages' do
      user = users(:user_two)
      result = Replace.call(user:, max_content_rating: '0', package_keys: %w[shelves another_world])

      assert_predicate result, :success?
      assert_equal 0, user.reload.content_filter.max_content_rating
      assert_equal %w[another_world shelves], user.hidden_packages.pluck(:package_key).sort
    end

    test 'a blank rating clears the cap and the packages' do
      user = users(:user_one)
      user.hidden_packages.create!(package_key: 'shelves')

      result = Replace.call(user:, max_content_rating: '', package_keys: [])

      assert_predicate result, :success?
      assert_nil user.reload.content_filter
      assert_empty user.hidden_packages.to_a
    end

    test 'an unknown rating writes nothing' do
      user = users(:user_one)

      result = Replace.call(user:, max_content_rating: '18', package_keys: ['shelves'])

      assert_equal I18n.t('content_filters.errors.rating'), result.error
      assert_equal 16, user.reload.content_filter.max_content_rating
      assert_empty user.hidden_packages
    end

    test 'rejects an unknown package and a third package' do
      user = users(:user_one_one_zero)

      unknown = Replace.call(user:, max_content_rating: '', package_keys: ['not-a-package'])
      capped = Replace.call(user:, max_content_rating: '16', package_keys: %w[shelves another_world romance_bl])

      assert_equal I18n.t('content_filters.errors.package'), unknown.error
      assert_equal I18n.t('content_filters.errors.cap'), capped.error
      assert_nil user.reload.content_filter
    end
  end
end
