# frozen_string_literal: true

require 'test_helper'

module Pokemons
  module Engine
    # What version 2 events tell must add up: HP, dodges, type effects and traits, over many random battles.
    class HpEventPropertiesTest < ActiveSupport::TestCase
      include HpBattleSamples

      EFFECTS = { 1 => 'super', -1 => 'weak', 0 => nil }.freeze

      test 'only a dodge does no damage; it follows an agile trigger and has no crit or effect' do
        each_round do |_start, hits, events|
          dodges = hits.select { |event| event.data[:dodged] }
          after_agile = events.each_cons(2).filter_map do |before, hit|
            hit if hit.type == :hit && before.data == { combatant: hit.data[:target], trait: 'agile' }
          end
          misses = hits.select { |event| event.data[:damage].zero? }

          assert_equal dodges, misses
          assert_equal dodges, after_agile
          assert(dodges.none? { |event| event.data[:crit] || event.data[:effect] })
        end
      end

      test 'HP follows every hit and heal, never leaves 0 to max, and a Pokémon faints right after reaching 0' do
        each_battle do |result, attacker, defender|
          ledger = HpLedger.new(combatants_by_id(attacker, defender).transform_values { |c| HpBalance::V2.hp(c) })
          checks = result.events.filter_map { |event| ledger.check(event) }

          assert(checks.all? { |expected, reported| (expected - reported).abs < 1e-9 })
          assert(result.events.each_cons(2).all? do |event, after|
            event.type != :hit || event.data[:hp_left].positive? || after.type == :fainted
          end)
        end
      end

      test 'a hit that lands is super effective or weak by the raw type chart' do
        each_battle do |result, attacker, defender|
          combatants = combatants_by_id(attacker, defender)
          landed = result.events_of(:hit).reject { |event| event.data[:dodged] }
          expected = landed.map do |event|
            striker, target = combatants.values_at(event.data[:striker], event.data[:target])
            EFFECTS[TypeChart.default.multiplier(striker.types, target.types) <=> 1.0]
          end
          effects = landed.map { |event| event.data[:effect] }

          assert_equal expected, effects
        end
      end

      test 'traits trigger only for their own Pokémon, and persistent saves it once per battle' do
        each_battle do |result, attacker, defender|
          combatants = combatants_by_id(attacker, defender)
          triggers = result.events_of(:trait_triggered).map { |event| event.data.values_at(:combatant, :trait) }

          assert(triggers.all? { |id, trait| combatants[id].character == trait })
          assert(triggers.tally.all? { |(_, trait), count| trait != 'persistent' || count == 1 })
        end
      end
    end
  end
end
