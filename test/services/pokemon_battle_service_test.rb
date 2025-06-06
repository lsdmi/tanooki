# frozen_string_literal: true

require 'test_helper'

class PokemonBattleServiceTest < ActiveSupport::TestCase
  def setup
    @attacker = users(:user_one)
    @defender = users(:user_two)
  end

  test 'battle log is updated during a battle (attacker stronger than defender' do
    service = PokemonBattleService.new(
      attacker_pokemons: @attacker.user_pokemons,
      defender_pokemons: @defender.user_pokemons,
      attacker_id: @attacker.id,
      defender_id: @defender.id
    )

    service.start_battle
    assert_not_empty service.fight_details
  end

  test 'battle log is update during a battle (defender stronger than attacker)' do
    service = PokemonBattleService.new(
      attacker_pokemons: @defender.user_pokemons,
      defender_pokemons: @attacker.user_pokemons,
      attacker_id: @attacker.id,
      defender_id: @defender.id
    )

    service.start_battle
    assert_not_empty service.fight_details
  end
end
