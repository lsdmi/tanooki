# frozen_string_literal: true

require 'test_helper'

module Pokemons
  class StatTiersTest < ActiveSupport::TestCase
    Stats = Data.define(:dex_id, :base_hp, :base_attack)

    test 'might reads the win rate in tiers 10 points wide' do
      tiers = [0.0, 0.249, 0.25, 0.5, 0.7, 0.75, 1.0].map { StatTiers.might_tier(it) }

      assert_equal [1, 1, 2, 4, 6, 7, 7], tiers
    end

    test 'might comes from the generated file: Snorlax tops it, Magikarp is at the bottom' do
      snorlax, magikarp = [143, 129].map { |dex_id| StatTiers.for(official(dex_id)).might }

      assert_equal [7, 1], [snorlax, magikarp]
    end

    test 'a species missing from the file takes the rate of the one closest in HP x attack' do
      snorlax_like = Stats.new(dex_id: 999, base_hp: 161, base_attack: 110)

      assert_in_delta StatTiers.win_rates.fetch(143), StatTiers.win_rate(snorlax_like)
    end

    test 'stamina follows HP, strike follows attack, in fifths of the species' do
      chansey = StatTiers.for(official(113))
      weakest = StatTiers.for(Stats.new(dex_id: 999, base_hp: 1, base_attack: 1))

      assert_equal [5, 1], [chansey.stamina, chansey.strike]
      assert_equal [1, 1], [weakest.stamina, weakest.strike]
    end

    test 'the file covers every species in the catalogue' do
      assert_operator StatTiers.win_rates.size, :>=, 140
      assert_operator StatTiers.win_rates.values.minmax, :all?, 0.0..1.0
    end

    private

    def official(dex_id)
      BaseStats.for(dex_id).then { |s| Stats.new(dex_id:, base_hp: s[:hp], base_attack: s[:attack]) }
    end
  end
end
