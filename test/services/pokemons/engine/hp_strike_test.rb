# frozen_string_literal: true

require 'test_helper'

module Pokemons
  module Engine
    class HpStrikeTest < ActiveSupport::TestCase
      # Returns the queued values in order, whatever the argument.
      QueuedRng = Struct.new(:queue) do
        def rand(*)
          queue.shift
        end
      end

      PLAIN_DRAWS = [1.0, 0.5].freeze

      test 'a hit draws the roll, then the crit' do
        weak = strike(draws: [0.7, 0.5])
        crit = strike(draws: [1.0, 0.1])

        assert_equal [70.0, false], [weak.damage, weak.crit]
        assert_equal [200.0, true], [crit.damage, crit.crit]
      end

      test 'the opening hit deals 40%, or 55% from an independent striker' do
        independent = strike(striker: fighter(1, character: 'independent'), opening: true)

        assert_in_delta 40.0, strike(opening: true).damage
        assert_in_delta 55.0, independent.damage
        assert_equal [[1, 'independent']], independent.triggers
      end

      test 'a decisive striker crits up to 20% of the time, and only those extra crits trigger it' do
        decisive = fighter(1, character: 'decisive')

        assert_equal [true, [[1, 'decisive']]], crit_and_triggers(strike(striker: decisive, draws: [1.0, 0.15]))
        assert_equal [true, []], crit_and_triggers(strike(striker: decisive, draws: [1.0, 0.1]))
        assert_equal [false, []], crit_and_triggers(strike(striker: decisive, draws: [1.0, 0.2]))
      end

      test 'only an agile target takes a third draw, and dodges 6% of hits' do
        agile = fighter(2, character: 'agile')
        dodged = strike(target: agile, draws: [*PLAIN_DRAWS, 0.05])
        unused = [*PLAIN_DRAWS, 0.05].tap { |draws| strike(draws:) }

        assert_equal [0.0, true, [[2, 'agile']]], [dodged.damage, dodged.dodged, dodged.triggers]
        assert_in_delta 100.0, strike(target: agile, draws: [*PLAIN_DRAWS, 0.06]).damage
        assert_equal [0.05], unused
      end

      test 'a dodge drops the crit, the effect and the striker triggers it drew' do
        striker = fighter(1, character: 'decisive').with(types: %w[fire])
        target = fighter(2, character: 'agile').with(types: %w[grass])
        dodged = strike(striker:, target:, draws: [1.0, 0.15, 0.01])

        assert_equal [false, nil, [[2, 'agile']]], [dodged.crit, dodged.effect, dodged.triggers]
      end

      test 'the effect is super or weak by the raw type chart, nil when neutral' do
        fire = fighter(1).with(types: %w[fire])
        grass = fighter(2).with(types: %w[grass])

        assert_equal 'super', strike(striker: fire, target: grass).effect
        assert_equal 'weak', strike(striker: grass, target: fire).effect
        assert_nil strike.effect
      end

      test 'a lucky striker rerolls a roll below 80% with a second draw' do
        lucky = fighter(1, character: 'lucky')
        rerolled = strike(striker: lucky, draws: [0.75, 0.9, 0.5])
        kept = strike(striker: lucky, draws: [0.8, 0.5])

        assert_equal [90.0, [[1, 'lucky']]], [rerolled.damage.round(9), rerolled.triggers]
        assert_equal [80.0, []], [kept.damage.round(9), kept.triggers]
      end

      test 'a hardy target takes 17% less below half HP' do
        weak = fighter(1, attack: 10.0)

        assert_in_delta 8.3, strike(striker: weak, target: fighter(2, character: 'hardy', hp_left: 49.0)).damage
        assert_in_delta 10.0, strike(striker: weak, target: fighter(2, character: 'hardy')).damage
      end

      test 'a persistent target survives one lethal hit above 45% HP at 1 HP' do
        survivor = strike(target: fighter(2, character: 'persistent', hp_left: 46.0)).target

        assert_equal [1.0, true], [survivor.hp, survivor.survived]
        assert_predicate strike(target: survivor).target.hp, :zero?
        assert_predicate strike(target: fighter(2, character: 'persistent', hp_left: 45.0)).target.hp, :zero?
      end

      test 'a friendly round winner gets back a tenth of its max HP, never above it' do
        cases = [['friendly', 50.0], ['friendly', 95.0], ['friendly', 100.0], [nil, 50.0]]
        recoveries = cases.map { |character, hp_left| HpTraits.recovery(fighter(1, character:, hp_left:)) }

        assert_equal [10.0, 5.0, nil, nil], recoveries
      end

      test 'a patient striker hits back harder once per round' do
        hit = strike(striker: fighter(1, character: 'patient').with(wounded: true))

        assert_in_delta 112.0, hit.damage
        assert_predicate hit.striker, :countered
        assert_in_delta 100.0, strike(striker: hit.striker).damage
      end

      test 'HP-based bonuses compare the striker with its own max HP or its opponent' do
        cases = [['ambitious', 40.0], ['ambitious', 60.0], ['prideful', 60.0], ['prideful', 40.0],
                 ['brave', 40.0], ['brave', 60.0], ['confident', 50.0], ['confident', 40.0]]
        bonuses = cases.map do |character, hp_left|
          HpTraits.attack_bonus(fighter(1, character:, hp_left:), fighter(2, hp_left: 50.0))
        end

        assert_equal [1.1, nil, 1.4, nil, 1.15, nil, 1.11, nil], bonuses
      end

      private

      def strike(striker: fighter(1), target: fighter(2), opening: false, draws: PLAIN_DRAWS.dup)
        HpStrike.call(striker:, target:, opening:, rng: QueuedRng.new(draws), balance: HpBalance::V2)
      end

      def crit_and_triggers(hit)
        [hit.crit, hit.triggers]
      end

      def fighter(id, character: nil, hp_left: 100.0, attack: 100.0)
        HpFighter.new(id:, character:, types: [], max_hp: 100.0, hp: hp_left, attack:, wounded: false,
                      countered: false, survived: false)
      end
    end
  end
end
