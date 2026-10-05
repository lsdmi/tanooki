# frozen_string_literal: true

require 'test_helper'

module Pokemons
  module Engine
    class HpBalanceTest < ActiveSupport::TestCase
      setup { @balance = HpBalance::V2 }

      test 'pulls species stats towards the mean' do
        snorlax = species(143)
        magikarp = species(129)

        assert_in_delta 77.1, @balance.hp(snorlax), 0.1
        assert_in_delta 50.9, @balance.hp(magikarp), 0.1
        assert_in_delta 1.49, @balance.attack(snorlax) / @balance.attack(magikarp), 0.01
      end

      test 'experience adds up to a fifth to HP and attack, capped at 100' do
        fresh = species(25)
        veteran = fresh.with(battle_experience: 100)
        ratios = [@balance.hp(veteran) / @balance.hp(fresh), @balance.attack(veteran) / @balance.attack(fresh),
                  @balance.hp(fresh.with(battle_experience: 50)) / @balance.hp(fresh)]

        assert_equal([1.2, 1.2, 1.1], ratios.map { |ratio| ratio.round(9) })
        assert_equal @balance.hp(veteran), @balance.hp(fresh.with(battle_experience: 115))
      end

      test 'an average Pokémon faints in two average hits' do
        average = Combatant.new(id: 1, character: nil, power_level: 1, battle_experience: 0, types: [],
                                base_hp: @balance.mean_hp, base_attack: @balance.mean_attack)
        average_hit = @balance.attack(average) * 0.85 * 1.125

        assert_in_delta 2.0, @balance.hp(average) / average_hit
      end

      test 'softens the type chart' do
        assert_in_delta 1.25**0.45, @balance.type_multiplier(%w[fire], %w[grass])
        assert_in_delta 1.0, @balance.type_multiplier(%w[normal], %w[normal])
      end

      private

      def species(dex_id)
        stats = BaseStats.for(dex_id)
        Combatant.new(id: dex_id, character: nil, power_level: 1, battle_experience: 0, types: [],
                      base_hp: stats[:hp], base_attack: stats[:attack])
      end
    end
  end
end
