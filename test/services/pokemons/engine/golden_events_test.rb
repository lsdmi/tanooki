# frozen_string_literal: true

require 'test_helper'

module Pokemons
  module Engine
    # Fixed teams and seeds with the whole event list pinned. A change here changes how battles are told and stored;
    # if it also changes outcomes, it needs a new engine version.
    class GoldenEventsTest < ActiveSupport::TestCase
      test 'two on two: round traits, tiredness traits and a comeback' do
        result = simulate([['hardy', 2, 50, %w[fire]], ['ambitious', 3, 20, %w[water]]],
                          [['agile', 3, 60, %w[grass]], ['friendly', 1, 10, %w[normal]]], seed: 11)

        assert_equal [
          [1, :round_started, { attacker: 2, defender: 101 }],
          [1, :trait_triggered, { combatant: 2, trait: 'ambitious' }],
          [1, :round_resolved, { attacker_score: 334.39577123412914, defender_score: 405.0 }],
          [1, :fainted, { combatant: 2, side: :attacker }],
          [1, :tired, { combatant: 101, tiredness: 1.25 }],
          [2, :round_started, { attacker: 1, defender: 101 }],
          [2, :round_resolved, { attacker_score: 282.46720252594565, defender_score: 215.37045075151855 }],
          [2, :fainted, { combatant: 101, side: :defender }],
          [2, :trait_triggered, { combatant: 1, trait: 'hardy' }],
          [2, :trait_triggered, { combatant: 101, trait: 'agile' }],
          [2, :tired, { combatant: 1, tiredness: 1.25 }],
          [3, :round_started, { attacker: 1, defender: 102 }],
          [3, :trait_triggered, { combatant: 102, trait: 'friendly' }],
          [3, :round_resolved, { attacker_score: 149.76863021454443, defender_score: 90.25561622295687 }],
          [3, :fainted, { combatant: 102, side: :defender }],
          [3, :trait_triggered, { combatant: 1, trait: 'hardy' }],
          [3, :tired, { combatant: 1, tiredness: 1.4 }],
          [3, :battle_won, { side: :attacker }]
        ], events(result)
        assert_equal({ 1 => 52, 2 => 22, 101 => 61, 102 => 12 }, result.experience)
      end

      test 'one on one: dual types against prideful, the defender wins' do
        result = simulate([['prideful', 4, 90, %w[psychic flying]]], [['lucky', 4, 95, %w[ghost]]], seed: 5)

        assert_equal [
          [1, :round_started, { attacker: 1, defender: 101 }],
          [1, :trait_triggered, { combatant: 1, trait: 'prideful' }],
          [1, :round_resolved, { attacker_score: 526.331765759613, defender_score: 557.5528427527248 }],
          [1, :fainted, { combatant: 1, side: :attacker }],
          [1, :tired, { combatant: 101, tiredness: 1.25 }],
          [1, :battle_won, { side: :defender }]
        ], events(result)
        assert_equal({ 1 => 92, 101 => 97 }, result.experience)
      end

      private

      def simulate(attacker, defender, seed:)
        Simulator.call(attacker: team(1, attacker), defender: team(101, defender), rng: Random.new(seed))
      end

      def team(first_id, specs)
        combatants = specs.each_with_index.map do |(character, power_level, battle_experience, types), index|
          Combatant.new(id: first_id + index, character:, power_level:, battle_experience:, types:)
        end
        TeamSnapshot.new(trainer_id: first_id, combatants:)
      end

      def events(result)
        result.events.map { |event| [event.round, event.type, event.data] }
      end
    end
  end
end
