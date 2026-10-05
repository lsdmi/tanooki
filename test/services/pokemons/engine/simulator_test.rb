# frozen_string_literal: true

require 'test_helper'

module Pokemons
  module Engine
    class SimulatorTest < ActiveSupport::TestCase
      test 'the same seed and teams give the same battle' do
        assert_equal simulate(seed: 7), simulate(seed: 7)
        assert_not_equal simulate(seed: 7).events, simulate(seed: 8).events
      end

      test 'touches neither the database nor the global random generator' do
        Kernel.srand(99)
        expected = Kernel.rand
        Kernel.srand(99)

        assert_no_queries { simulate(seed: 7) }
        assert_in_delta expected, Kernel.rand
      end

      test 'fights until one team has nobody left' do
        result = simulate(seed: 3)
        fainted = result.events_of(:fainted).map { |event| event.data[:side] }

        assert_equal 3, fainted.count(result.attacker_won? ? :defender : :attacker)
        assert_equal result.events_of(:round_started).size, fainted.size
        assert_equal [:battle_won, { side: result.winner }], result.events.last.to_h.values_at(:type, :data)
      end

      test 'fields at most the smaller team, up to the team size' do
        result = Simulator.call(attacker: team(1, %w[hardy] * 8), defender: team(101, %w[agile] * 7),
                                rng: Random.new(1))
        starts = result.events_of(:round_started)
        fielded = %i[attacker defender].map { |side| starts.map { |event| event.data[side] }.uniq.size }

        assert_equal BattleBalance::V1.team_size, fielded.max
        assert_operator fielded.min, :<=, BattleBalance::V1.team_size
      end

      test 'reports trait hooks as they fire' do
        result = Simulator.call(attacker: team(1, %w[friendly]), defender: team(101, %w[prideful]), rng: Random.new(1))
        traits = result.events_of(:trait_triggered).map { |event| event.data.values_at(:combatant, :trait) }

        assert_equal [[1, 'friendly'], [101, 'prideful']], traits
      end

      test 'only reports experience that changed' do
        result = Simulator.call(attacker: team(1, %w[hardy], experience: 100),
                                defender: team(101, %w[hardy], experience: 0), rng: Random.new(1))

        assert_equal({ 101 => 2 }, result.experience)
        assert_equal Simulator::VERSION, result.engine_version
      end

      private

      def simulate(seed:)
        Simulator.call(attacker: team(1, %w[lucky brave confident]), defender: team(101, %w[agile prideful friendly]),
                       rng: Random.new(seed))
      end

      def team(first_id, characters, experience: 20)
        TeamSnapshot.new(trainer_id: first_id, combatants: characters.each_with_index.map do |character, index|
          Combatant.new(id: first_id + index, character:, power_level: (index % 5) + 1, battle_experience: experience,
                        types: [index.even? ? 'fire' : 'water'])
        end)
      end
    end
  end
end
