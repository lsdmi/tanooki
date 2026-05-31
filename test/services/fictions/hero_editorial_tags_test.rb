# frozen_string_literal: true

require 'test_helper'

module Fictions
  class HeroEditorialTagsTest < ActiveSupport::TestCase
    setup do
      @fiction = fictions(:one)
    end

    test 'returns adult first then novelty up to hero max' do
      @fiction.update!(adult_content: true)

      kinds = HeroEditorialTags.new(
        @fiction,
        popular_novelty_ids: [@fiction.id],
        top_fiction_ids: [@fiction.id],
        latest_update_ids: [@fiction.id]
      ).call

      assert_equal %i[adult novelty], kinds
    end

    test 'returns editorial tags in priority order without adult' do
      kinds = HeroEditorialTags.new(
        @fiction,
        popular_novelty_ids: [@fiction.id],
        top_fiction_ids: [@fiction.id],
        latest_update_ids: [@fiction.id]
      ).call

      assert_equal %i[novelty popular], kinds
    end

    test 'maps latest updates to update kind' do
      kinds = HeroEditorialTags.new(
        @fiction,
        popular_novelty_ids: [],
        top_fiction_ids: [],
        latest_update_ids: [@fiction.id]
      ).call

      assert_equal [:update], kinds
    end
  end
end
