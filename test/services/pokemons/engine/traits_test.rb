# frozen_string_literal: true

require 'test_helper'

module Pokemons
  module Engine
    class TraitsTest < ActiveSupport::TestCase
      test 'has one trait per UserPokemon character' do
        assert_equal UserPokemon.characters.keys.sort, Traits.registry.keys.sort
        assert_equal UserPokemon.characters.keys.sort, Traits.registry.values.map(&:key).sort
      end

      test 'falls back to the base rules for a missing or unknown character' do
        assert_same Traits::BASE, Traits.for(nil)
        assert_same Traits::BASE, Traits.for('calm')
        assert_instance_of Traits::Hardy, Traits.for(:hardy)
      end

      test 'roster traits change luck, power and experience' do
        assert_equal 1.0..1.2, Traits.for('lucky').luck_range
        assert_equal 120, Traits.for('independent').power_multiplier
        assert_equal 2, Traits.for('brave').experience_multiplier
      end

      test 'base experience gain stops at the cap' do
        base = Traits::BASE

        assert_equal 52, base.experience_after(50, 2, 100)
        assert_equal 50, base.experience_after(50, 0, 100)
        assert_equal 100, base.experience_after(100, 2, 100)
      end

      test 'confident doubles its gain up to 115' do
        confident = Traits.for('confident')

        assert_equal 104, confident.experience_after(100, 2, 100)
        assert_equal 115, confident.experience_after(115, 2, 100)
        assert_equal 50, confident.experience_after(50, 0, 100)
      end

      test 'persistent gains a point every round below 115' do
        persistent = Traits.for('persistent')

        assert_equal 51, persistent.experience_after(50, 0, 100)
        assert_equal 113, persistent.experience_after(112, 2, 100)
        assert_equal 115, persistent.experience_after(115, 2, 100)
      end

      test 'hardy tires less after a win and agile tires the winner more' do
        assert_in_delta(-0.1, Traits.for('hardy').after_victory)
        assert_in_delta 0.1, Traits.for('agile').after_defeat
        assert_nil Traits::BASE.after_victory
      end

      test 'friendly drops both sides experience from their strength' do
        own, opponent = Traits.for('friendly').before_round(fighter(experience: 30), fighter(experience: 50, luck: 0.5))

        assert_equal [1, 1], [own.experience, opponent.experience]
        assert_in_delta 100.0, own.raw_total
        assert_in_delta 50.0, opponent.raw_total
      end

      test 'ambitious pins the opponent luck to the bottom of its range' do
        _, plain = Traits.for('ambitious').before_round(fighter, fighter(luck: 1.05, experience: 10))
        _, lucky = Traits.for('ambitious').before_round(fighter, fighter(character: 'lucky', luck: 1.15))

        assert_in_delta 99.0, plain.raw_total
        assert_in_delta 1.0, lucky.luck
        assert_in_delta 100.0, lucky.raw_total
      end

      test 'prideful divides the opponent power by 1.2' do
        own, opponent = Traits.for('prideful').before_round(fighter, fighter(power: 120, experience: 10))

        assert_equal fighter, own
        assert_in_delta 100.0, opponent.power
        assert_in_delta 110.0, opponent.raw_total
      end

      test 'patient and decisive only act on unequal type multipliers' do
        assert_nil Traits.for('patient').before_round(fighter, fighter)
        assert_in_delta 0.5, Traits.for('patient').before_round(fighter(type: 0.5), fighter(type: 1.25)).last.type
        assert_in_delta 1.35, Traits.for('decisive').before_round(fighter(type: 1.25), fighter).first.type
      end

      test 'only round traits have a round priority, friendly first' do
        priorities = Traits.registry.values.select(&:round_priority).sort_by(&:round_priority).map(&:key)

        assert_equal %w[friendly ambitious prideful patient decisive], priorities
      end

      private

      def fighter(**overrides)
        attributes = { id: 1, character: nil, types: [], power: 100, luck: 1.0, experience: 0, type: 1, tiredness: 1,
                       active: true }.merge(overrides)
        Fighter.new(**attributes, raw_total: Fighter.strength(attributes[:power], attributes[:luck],
                                                              attributes[:experience]))
      end
    end
  end
end
