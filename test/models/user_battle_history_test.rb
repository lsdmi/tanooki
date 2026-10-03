# frozen_string_literal: true

require 'test_helper'

# Battle history reads pokemon_battles only; battles from pokemon_battle_logs were converted to legacy rows.
class UserBattleHistoryTest < ActiveSupport::TestCase
  include PokemonBattleHelpers

  setup do
    @user = users(:user_one)
    @rival = users(:user_two)
  end

  test 'the latest battle is the newest row, legacy or not' do
    create_pokemon_battle(attacker: @rival, defender: @user, created_at: 2.days.ago)
    legacy = create_pokemon_battle(attacker: @user, defender: @rival, engine_version: PokemonBattle::LEGACY_VERSION,
                                   created_at: 1.day.ago)

    assert_equal legacy, @user.latest_battle
  end

  test 'unconverted logs are not read' do
    PokemonBattleLog.create!(attacker: @user, defender: @rival, winner: @user)

    assert_nil @user.latest_battle
    assert_nil @user.last_battle_at
    assert_equal [0, 0], [@user.battle_victory_count, @user.battle_total_count]
  end

  test 'victories and totals count legacy rows' do
    create_pokemon_battle(attacker: @user, defender: @rival, engine_version: PokemonBattle::LEGACY_VERSION)
    create_pokemon_battle(attacker: @rival, defender: @user, winner: @rival)
    create_pokemon_battle(attacker: @user, defender: @rival, winner: @user)

    assert_equal [2, 3], [@user.battle_victory_count, @user.battle_total_count]
  end

  test 'destroying a user removes their battle logs and battles' do
    trainer = User.find(105) # users fixture user_105: no chapters or teams to block destroy
    PokemonBattleLog.create!(attacker: @rival, defender: trainer, winner: @rival)
    create_pokemon_battle(attacker: trainer, defender: @rival)

    trainer.destroy!

    assert_equal [0, 0], [PokemonBattleLog.where(defender_id: trainer.id).count,
                          PokemonBattle.involving(trainer).count]
  end
end
