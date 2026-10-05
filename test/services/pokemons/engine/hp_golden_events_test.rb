# frozen_string_literal: true

require 'test_helper'

module Pokemons
  module Engine
    # Version 2 battles with fixed teams and seeds, the whole event list pinned. A change here changes how battles are
    # told and stored; if it also changes outcomes, it needs a new engine version once version 2 is live.
    class HpGoldenEventsTest < ActiveSupport::TestCase
      test 'two on two: a dodge, crits, weak and super effective hits, a heal and a lucky reroll' do
        result = simulate([['friendly', 25, 40, %w[electric]], ['lucky', 7, 10, %w[water]]],
                          [['agile', 4, 30, %w[fire]], ['persistent', 1, 0, %w[grass poison]]], seed: 815)

        assert_equal [
          [1, :round_started, { attacker: 1, defender: 101, first_striker: 1 }],
          [1, :trait_triggered, { combatant: 101, trait: 'agile' }],
          [1, :hit, hit([1, 101], 0.0, 61.604340735686336, dodged: true)],
          [1, :hit, hit([101, 1], 27.238665694154403, 34.18417416307234)],
          [1, :hit, hit([1, 101], 63.876174690777134, 0.0, crit: true)],
          [1, :fainted, { combatant: 101, side: :defender }],
          [1, :trait_triggered, { combatant: 1, trait: 'friendly' }],
          [1, :healed, { combatant: 1, amount: 6.142283985722675, hp_left: 40.32645814879502 }],
          [2, :round_started, { attacker: 1, defender: 102, first_striker: 1 }],
          [2, :hit, hit([1, 102], 8.643985984942523, 51.1606746613973, effect: 'weak')],
          [2, :hit, hit([102, 1], 26.462741394377105, 13.863716754417915)],
          [2, :hit, hit([1, 102], 43.468299578853646, 7.692375082543656, crit: true, effect: 'weak')],
          [2, :hit, hit([102, 1], 26.91190894498498, 0.0)],
          [2, :fainted, { combatant: 1, side: :attacker }],
          [3, :round_started, { attacker: 2, defender: 102, first_striker: 102 }],
          [3, :hit, hit([102, 2], 12.614325463085914, 48.112871387747404, effect: 'super')],
          [3, :trait_triggered, { combatant: 2, trait: 'lucky' }],
          [3, :hit, hit([2, 102], 30.751276014979805, 0.0)],
          [3, :fainted, { combatant: 102, side: :defender }],
          [3, :battle_won, { side: :attacker }]
        ], events(result)
        assert_equal({ 1 => 41, 2 => 11, 101 => 31, 102 => 2 }, result.experience)
      end

      test 'one on one: persistent survives a lethal crit at 1 HP and wins' do
        result = simulate([['decisive', 6, 50, %w[fire flying]]], [['persistent', 9, 20, %w[water]]],
                          seed: 270)

        assert_equal [
          [1, :round_started, { attacker: 1, defender: 101, first_striker: 1 }],
          [1, :hit, hit([1, 101], 12.503061540356498, 57.103677005544114, effect: 'weak')],
          [1, :hit, hit([101, 1], 70.64424812520716, 2.7909267334114247, crit: true, effect: 'super')],
          [1, :trait_triggered, { combatant: 101, trait: 'persistent' }],
          [1, :hit, hit([1, 101], 66.66010837132451, 1.0, crit: true, effect: 'weak')],
          [1, :hit, hit([101, 1], 61.308709171786816, 0.0, crit: true, effect: 'super')],
          [1, :fainted, { combatant: 1, side: :attacker }],
          [1, :battle_won, { side: :defender }]
        ], events(result)
        assert_equal({ 101 => 21 }, result.experience)
      end

      private

      def simulate(attacker, defender, seed:)
        HpSimulator.call(attacker: team(1, attacker), defender: team(101, defender), rng: Random.new(seed))
      end

      def team(first_id, specs)
        combatants = specs.each_with_index.map do |(character, dex_id, battle_experience, types), index|
          stats = BaseStats.for(dex_id)
          Combatant.new(id: first_id + index, character:, power_level: 1, battle_experience:, types:,
                        base_hp: stats[:hp], base_attack: stats[:attack])
        end
        TeamSnapshot.new(trainer_id: first_id, combatants:)
      end

      def hit((striker, target), damage, hp_left, **flags)
        { striker:, target:, damage:, hp_left:, crit: false, dodged: false, effect: nil, **flags }
      end

      def events(result)
        result.events.map { |event| [event.round, event.type, event.data] }
      end
    end
  end
end
