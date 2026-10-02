# frozen_string_literal: true

require 'test_helper'

module Pokemons
  class BattleRunTest < ActiveSupport::TestCase
    def setup
      @attacker = users(:user_one)
      @defender = users(:user_two)
      UserPokemon.create!(user: @attacker, pokemon: pokemons(:two), character: :brave, battle_experience: 40)
      UserPokemon.create!(user: @defender, pokemon: pokemons(:three), character: :hardy, battle_experience: 10)
    end

    test 'saves the experience and winner the simulator decided for the seed' do
      expected = Engine::Simulator.call(attacker: snapshot(@attacker), defender: snapshot(@defender),
                                        rng: Random.new(42))
      run = battle_run(@attacker, @defender, seed: 42).tap(&:start_battle)
      saved = UserPokemon.where(id: expected.experience.keys).pluck(:id, :battle_experience).to_h

      assert_equal winner_and_loser(expected), [run.winner_id, run.loser_id]
      assert_equal expected.experience, saved
      assert_equal expected.events_of(:round_started).size, run.outcome_blocks.size
    end

    test 'renders a log whichever side is stronger' do
      [[@attacker, @defender], [@defender, @attacker]].each do |attacker, defender|
        assert_not_empty battle_run(attacker, defender).tap(&:start_battle).fight_details
      end
    end

    private

    def battle_run(attacker, defender, **)
      BattleRun.new(attacker_pokemons: attacker.user_pokemons, defender_pokemons: defender.user_pokemons,
                    attacker_id: attacker.id, defender_id: defender.id, **)
    end

    def snapshot(user)
      Engine::TeamSnapshot.new(trainer_id: user.id, combatants: user.user_pokemons.order(:id).map do |record|
        Engine::Combatant.new(id: record.id, character: record.character,
                              power_level: Pokemon::POWER_LEVELS.fetch(record.pokemon.power_level),
                              battle_experience: record.battle_experience, types: record.pokemon.types.map(&:name))
      end)
    end

    def winner_and_loser(result)
      result.attacker_won? ? [@attacker.id, @defender.id] : [@defender.id, @attacker.id]
    end
  end
end
