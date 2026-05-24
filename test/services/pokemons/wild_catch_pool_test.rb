# frozen_string_literal: true

require 'test_helper'

module Pokemons
  class WildCatchPoolTest < ActiveSupport::TestCase
    test 'weighted_ids returns cached pokemon ids' do
      ids = WildCatchPool.weighted_ids

      assert_predicate ids, :any?
      assert(ids.all? { |id| Pokemon.exists?(id) })
    end

    test 'sample_id returns a valid pokemon id' do
      sampled = WildCatchPool.sample_id

      assert Pokemon.exists?(sampled)
    end

    test 'rarity level 1 is weighted higher than level 4' do
      level_one_count = WildCatchPool.weighted_ids.count { |id| id == pokemons(:one).id }
      level_four_weight = WildCatchPool::RARITY_WEIGHTS[4]

      assert_operator level_one_count, :>, level_four_weight
    end
  end
end
