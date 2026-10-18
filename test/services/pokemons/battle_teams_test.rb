# frozen_string_literal: true

require 'test_helper'

module Pokemons
  class BattleTeamsTest < ActiveSupport::TestCase
    setup do
      @attacker = users(:user_one)
      @defender = users(:user_two)
      @brave = UserPokemon.create!(user: @attacker, pokemon: pokemons(:four), character: :brave, battle_experience: 40)
      @attacker.trainer_profile.update!(attack_team_ids: [@brave.id, user_pokemons(:one).id])
      @defender.trainer_profile.update!(defense_team_ids: [user_pokemons(:two).id])
    end

    test 'snapshots the attacker attack roster and the defender defense roster in order' do
      teams = BattleTeams.new(@attacker, @defender)

      assert_equal [@brave.id, user_pokemons(:one).id], teams.snapshot(:attacker).combatants.map(&:id)
      assert_equal [user_pokemons(:two).id], teams.snapshot(:defender).combatants.map(&:id)
    end

    test 'stores each fielded combatant with its species' do
      stored = BattleTeams.new(@attacker, @defender).stored(:defender)

      assert_equal [{ id: user_pokemons(:two).id, character: 'agile', power_level: nil, battle_experience: 1,
                      types: %w[normal], base_hp: 45, base_attack: 65, pokemon_id: pokemons(:one).id }], stored
    end

    test 'writes back only the experience that changed' do
      BattleTeams.new(@attacker, @defender).save_experience({ @brave.id => 44 })

      assert_equal [44, 1], [@brave.reload.battle_experience, user_pokemons(:one).reload.battle_experience]
    end

    test 'falls back to an auto roster when attack ids are blank' do
      @attacker.trainer_profile.update!(attack_team_ids: nil)
      ids = BattleTeams.new(@attacker, @defender).snapshot(:attacker).combatants.map(&:id)

      assert_operator ids.size, :<=, Balance::TEAM_SIZE
      assert_predicate ids, :any?
    end
  end
end
