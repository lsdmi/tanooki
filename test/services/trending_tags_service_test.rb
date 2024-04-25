# frozen_string_literal: true

require 'test_helper'

class TrendingTagsServiceTest < ActiveSupport::TestCase
  setup do
    @service = TrendingTagsService.new
  end

  test 'should return an array of Tag objects' do
    result = @service.navbar
    assert_instance_of Hash, result.first
  end

  test 'should return at most 5 trending tags' do
    result = @service.navbar
    assert_operator result.size, :<=, 5
  end

  test 'should return trending tags ordered by name' do
    result = @service.navbar
    assert_equal [tags(:one).name, 'Блоги', 'Відео', 'Обговорення', 'Ранобе'], result.pluck(:name)
  end

  test 'should return cached result if available' do
    Rails.cache.write('trending_tags', [tags(:one), tags(:two)])
    result = @service.navbar
    assert_equal [tags(:one).name, 'Блоги', 'Відео', 'Обговорення', 'Ранобе'], result.pluck(:name)
  end
end
