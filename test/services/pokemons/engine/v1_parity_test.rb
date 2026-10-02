# frozen_string_literal: true

require 'test_helper'

module Pokemons
  module Engine
    # pokemon_engine_v1_golden.json was recorded from the legacy Battle::Engine (commit 1f0da13b) with srand(seed):
    # 64 seeded scenarios covering every character on both sides. Version 1 must reproduce it exactly, down to each
    # round's float scores.
    class V1ParityTest < ActiveSupport::TestCase
      GOLDEN = JSON.parse(Rails.root.join('test/fixtures/files/pokemon_engine_v1_golden.json').read).freeze
      DEFENDER_IDS = 1001

      GOLDEN.each do |scenario|
        test "seed #{scenario['seed']} replays the legacy battle" do
          result = simulate(scenario)

          assert_equal expected_rounds(scenario), rounds(result)
          assert_equal scenario['winner'], result.winner.to_s
          assert_equal scenario['experience'], experience(scenario, result)
        end
      end

      private

      def simulate(scenario)
        Simulator.call(attacker: snapshot(scenario['attacker'], 1),
                       defender: snapshot(scenario['defender'], DEFENDER_IDS), rng: Random.new(scenario['seed']))
      end

      def snapshot(specs, first_id)
        TeamSnapshot.new(trainer_id: first_id, combatants: specs.each_with_index.map do |spec, index|
          Combatant.new(id: first_id + index, character: spec['character'], power_level: spec['power_level'],
                        battle_experience: spec['battle_experience'], types: spec['types'])
        end)
      end

      def expected_rounds(scenario)
        scenario['rounds'].map { |round| round.values_at('attacker', 'defender', 'scores', 'winner') }
      end

      def rounds(result)
        starts, scores, fainted = %i[round_started round_resolved fainted].map { |type| result.events_of(type) }
        starts.zip(scores, fainted).map { |events| round(*events.map(&:data)) }
      end

      def round(start, score, fainted)
        [start[:attacker] - 1, start[:defender] - DEFENDER_IDS,
         score.values_at(:attacker_score, :defender_score).map(&:to_s),
         fainted[:side] == :defender ? 'attacker' : 'defender']
      end

      def experience(scenario, result)
        { 'attacker' => final_experience(scenario['attacker'], 1, result),
          'defender' => final_experience(scenario['defender'], DEFENDER_IDS, result) }
      end

      def final_experience(specs, first_id, result)
        specs.each_with_index.map { |spec, index| result.experience.fetch(first_id + index, spec['battle_experience']) }
      end
    end
  end
end
