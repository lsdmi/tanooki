# frozen_string_literal: true

require 'test_helper'

module Pokemons
  module Engine
    class HpSimulatorTest < ActiveSupport::TestCase
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

      test 'runs through Engine.simulate as version 2' do
        attacker = team(1, [[6, 30], [25, 100]])
        defender = team(101, [[143, 50], [129, 0]])
        result = Engine.simulate(attacker:, defender:, seed: 3, version: 2)

        assert_equal 2, result.engine_version
        assert_equal HpSimulator.call(attacker:, defender:, rng: Random.new(3)), result
      end

      test 'fields the strongest by HP x attack, at most the smaller team, up to the team size' do
        attacker = team(1, [*Array.new(7) { [129, 0] }, [143, 0]])
        result = HpSimulator.call(attacker:, defender: team(101, Array.new(8) { [25, 0] }), rng: Random.new(1))
        starts = result.events_of(:round_started)

        assert_equal 8, starts.first.data[:attacker]
        assert_operator starts.map { |event| event.data[:attacker] }.uniq.size, :<=, HpBalance::V2.team_size
        assert_operator starts.map { |event| event.data[:defender] }.uniq.size, :<=, HpBalance::V2.team_size
      end

      test 'the round winner keeps its HP for the next round' do
        result = HpSimulator.call(attacker: team(1, [[149, 100], [129, 0], [129, 0]]),
                                  defender: team(101, [[129, 0], [129, 0], [129, 0]]), rng: Random.new(2))
        hits_on_dragonite = result.events_of(:hit).select { |event| event.data[:target] == 1 }

        assert_operator result.events_of(:round_started).count { |event| event.data[:attacker] == 1 }, :>, 1
        hits_on_dragonite.each_cons(2) do |before, after|
          assert_in_delta [before.data[:hp_left] - after.data[:damage], 0].max, after.data[:hp_left]
        end
      end

      test 'a friendly round winner gets back up to a tenth of its HP' do
        attacker = team(1, [[149, 100, 'friendly'], [129, 0], [129, 0]])
        result = HpSimulator.call(attacker:, defender: team(101, Array.new(3) { [129, 0] }), rng: Random.new(2))
        heals = result.events_of(:healed)
        hp_left = HpBalance::V2.hp(attacker.combatants.first)

        assert_not_empty heals
        assert(heals.all? { |event| event.data[:amount] <= hp_left * HpTraits::FRIENDLY_HEAL })
        result.events.select { |event| event.data[:target] == 1 || event.type == :healed }.each do |event|
          assert_in_delta hp_left + event.data[:amount], event.data[:hp_left] if event.type == :healed
          hp_left = event.data[:hp_left]
        end
      end

      test 'only reports experience that changed' do
        result = HpSimulator.call(attacker: team(1, [[25, 100]]), defender: team(101, [[25, 0]]), rng: Random.new(1))

        assert_equal({ 101 => 1 }, result.experience)
      end

      test 'refuses a snapshot without base stats' do
        stale = TeamSnapshot.new(trainer_id: 1, combatants: [Combatant.new(id: 1, character: 'lucky', power_level: 3,
                                                                           battle_experience: 0, types: %w[water])])

        assert_raises(HpSimulator::MissingStats) do
          HpSimulator.call(attacker: stale, defender: team(101, [[25, 0]]), rng: Random.new(1))
        end
      end

      private

      def simulate(seed:)
        HpSimulator.call(attacker: team(1, [[6, 30], [25, 100], [94, 0]]),
                         defender: team(101, [[143, 50], [3, 20], [130, 10]]), rng: Random.new(seed))
      end

      def team(first_id, specs)
        combatants = specs.each_with_index.map do |(dex_id, experience, character), index|
          stats = BaseStats.for(dex_id)
          Combatant.new(id: first_id + index, character:, power_level: 1, battle_experience: experience,
                        types: [index.even? ? 'fire' : 'water'], base_hp: stats[:hp], base_attack: stats[:attack])
        end
        TeamSnapshot.new(trainer_id: first_id, combatants:)
      end
    end
  end
end
