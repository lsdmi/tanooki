# frozen_string_literal: true

require 'test_helper'

module Pokemons
  module Engine
    # Invariants over many random battles. The seeds are fixed, so a failure always reproduces.
    class PropertiesTest < ActiveSupport::TestCase
      SEEDS = (1..200)
      DEFENDER_IDS = 1001
      CHARACTERS = [nil, *Traits.registry.keys].freeze

      # Rolls the same luck for everyone, so both sides' rosters do not depend on which side rolls first.
      FixedLuck = Struct.new(:position) do
        def rand(range)
          range.begin + ((range.end - range.begin) * position)
        end
      end

      test 'every battle ends with exactly one winner' do
        each_battle do |result|
          assert_equal [result.events.last], result.events_of(:battle_won)
          assert_equal result.winner, result.events.last.data[:side]
        end
      end

      test 'one Pokémon faints per round until the loser has nobody left' do
        each_battle do |result, attacker, defender|
          roster = [BattleBalance::V1.team_size, attacker.combatants.size, defender.combatants.size].min
          faints = result.events_of(:fainted).map { |event| event.data[:side] }.tally

          assert_equal roster, faints[result.attacker_won? ? :defender : :attacker]
          assert_operator faints.fetch(result.winner, 0), :<, roster
          assert_equal result.events_of(:round_started).size, faints.values.sum
        end
      end

      test 'tiredness only grows' do
        each_battle do |result|
          result.events_of(:tired).group_by { |event| event.data[:combatant] }.each_value do |events|
            levels = [1, *events.map { |event| event.data[:tiredness] }]

            assert levels.each_cons(2).all? { |before, after| after > before }, "tiredness #{levels}"
          end
        end
      end

      test 'experience never drops and only changes for Pokémon that fought' do
        each_battle do |result, attacker, defender|
          start = (attacker.combatants + defender.combatants).to_h { |c| [c.id, c.battle_experience] }
          fought = result.events_of(:round_started).flat_map { |event| event.data.values_at(:attacker, :defender) }

          assert_empty result.experience.keys - fought
          assert(result.experience.all? { |id, experience| experience > start[id] })
        end
      end

      # Version 1 gives a tied round to the defender, so battles with a tie cannot mirror.
      test 'swapping sides mirrors the battle when luck is the same for both' do
        compared = 0
        each_battle(rng: FixedLuck.new(0.5)) do |result, attacker, defender|
          next if rounds(result).any? { |_, scores| scores.uniq.one? }

          compared += 1
          swapped = Simulator.call(attacker: defender, defender: attacker, rng: FixedLuck.new(0.5))

          assert_equal [mirrored(rounds(result)), result.experience], [rounds(swapped), swapped.experience]
          assert_not_equal result.winner, swapped.winner
        end

        assert_operator compared, :>, SEEDS.size * 0.9
      end

      private

      def each_battle(rng: nil)
        SEEDS.each do |seed|
          random = Random.new(seed)
          attacker = team(random, 1)
          defender = team(random, DEFENDER_IDS)
          yield Simulator.call(attacker:, defender:, rng: rng || random), attacker, defender
        end
      end

      def team(random, first_id)
        TeamSnapshot.new(trainer_id: first_id, combatants: Array.new(random.rand(1..8)) do |index|
          Combatant.new(id: first_id + index, character: CHARACTERS.sample(random:), power_level: random.rand(1..5),
                        battle_experience: random.rand(0..120),
                        types: TypeChart.default.types.sample(random.rand(1..2), random:))
        end)
      end

      def rounds(result)
        result.events_of(:round_resolved).zip(result.events_of(:round_started)).map do |score, start|
          [start.data.values_at(:attacker, :defender), score.data.values_at(:attacker_score, :defender_score)]
        end
      end

      def mirrored(rounds)
        rounds.map { |ids, scores| [ids.reverse, scores.reverse] }
      end
    end
  end
end
