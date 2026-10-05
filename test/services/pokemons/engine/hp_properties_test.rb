# frozen_string_literal: true

require 'test_helper'

module Pokemons
  module Engine
    # Version 2 battle invariants over many random battles: winner, faints, turn order, experience, mirroring.
    class HpPropertiesTest < ActiveSupport::TestCase
      include HpBattleSamples

      test 'every battle ends with exactly one winner' do
        each_battle do |result|
          assert_equal [result.events.last], result.events_of(:battle_won)
          assert_equal result.winner, result.events.last.data[:side]
        end
      end

      test 'one Pokémon faints per round until the loser has nobody left' do
        each_battle do |result, attacker, defender|
          roster = [HpBalance::V2.team_size, attacker.combatants.size, defender.combatants.size].min
          faints = result.events_of(:fainted).map { |event| event.data[:side] }.tally

          assert_equal roster, faints[result.attacker_won? ? :defender : :attacker]
          assert_operator faints.fetch(result.winner, 0), :<, roster
          assert_equal result.events_of(:round_started).size, faints.values.sum
        end
      end

      test 'a round opens with its first striker, and the two in it alternate' do
        each_round do |start, hits|
          strikers = hits.map { |event| event.data[:striker] }
          targets = hits.map { |event| event.data[:target] }

          assert_equal start.data[:first_striker], strikers.first
          assert(strikers.each_cons(2).all? { |before, after| before != after })
          assert_equal start.data.values_at(:attacker, :defender).sort, (strikers | targets).sort
        end
      end

      test 'experience never drops and only changes for Pokémon that fought' do
        each_battle do |result, attacker, defender|
          start = combatants_by_id(attacker, defender).transform_values(&:battle_experience)
          fought = result.events_of(:round_started).flat_map { |event| event.data.values_at(:attacker, :defender) }

          assert_empty result.experience.keys - fought
          assert(result.experience.all? { |id, experience| experience > start[id] })
        end
      end

      test 'swapping sides with the same seed mirrors the battle' do
        each_battle do |result, attacker, defender, seed|
          swapped = HpSimulator.call(attacker: defender, defender: attacker, rng: Random.new(seed))

          assert_equal mirrored(result.events), swapped.events
          assert_equal result.experience, swapped.experience
        end
      end

      private

      # The attacker and defender keys swap, and so does the side a faint or win belongs to.
      def mirrored(events)
        swap = { attacker: :defender, defender: :attacker }
        events.map do |event|
          event.with(data: event.data.to_h { |key, value| [swap.fetch(key, key), key == :side ? swap[value] : value] })
        end
      end
    end
  end
end
