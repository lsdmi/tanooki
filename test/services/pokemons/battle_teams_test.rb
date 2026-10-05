# frozen_string_literal: true

require 'test_helper'

module Pokemons
  class BattleTeamsTest < ActiveSupport::TestCase
    setup do
      @attacker = users(:user_one)
      @defender = users(:user_two)
      @brave = UserPokemon.create!(user: @attacker, pokemon: pokemons(:two), character: :brave, battle_experience: 40)
    end

    test 'loads both teams with one preload, whatever the team size' do
      teams = assert_queries_count(4) do
        BattleTeams.new(@attacker, @defender).tap { |t| t.snapshot(:attacker) && t.snapshot(:defender) }
      end

      assert_equal [@attacker, @defender], teams.trainers
    end

    test 'snapshots each side in id order with the engine inputs' do
      combatant = BattleTeams.new(@attacker, @defender).snapshot(:attacker).combatants.last

      assert_equal [user_pokemons(:one).id, @brave.id],
                   BattleTeams.new(@attacker, @defender).snapshot(:attacker).combatants.map(&:id)
      assert_equal ['brave', 40, nil], [combatant.character, combatant.battle_experience, combatant.power_level]
    end

    test 'stores each combatant with its species' do
      stored = BattleTeams.new(@attacker, @defender).stored(:defender)

      assert_equal [{ id: user_pokemons(:two).id, character: 'agile', power_level: nil, battle_experience: 1,
                      types: %w[Звичайний], base_hp: 45, base_attack: 65, pokemon_id: pokemons(:one).id }], stored
    end

    test 'writes back only the experience that changed' do
      BattleTeams.new(@attacker, @defender).save_experience({ @brave.id => 44 })

      assert_equal [44, 1], [@brave.reload.battle_experience, user_pokemons(:one).reload.battle_experience]
    end
  end
end
