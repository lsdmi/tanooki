# frozen_string_literal: true

require 'test_helper'

# Until Phase 2.4 converts them, battles before pokemon_battles stay in pokemon_battle_logs; reads cover both.
class UserBattleHistoryTest < ActiveSupport::TestCase
  include PokemonBattleHelpers

  setup do
    @user = users(:user_one)
    @rival = users(:user_two)
  end

  test 'the latest battle prefers pokemon_battles over older logs' do
    PokemonBattleLog.create!(attacker: @user, defender: @rival, winner: @user, created_at: 1.day.ago)
    battle = create_pokemon_battle(attacker: @rival, defender: @user, created_at: 2.days.ago)

    assert_equal battle, @user.latest_battle
  end

  test 'falls back to the latest log when there is no new battle' do
    log = PokemonBattleLog.create!(attacker: @user, defender: @rival, winner: @user)

    assert_equal log, @user.latest_battle
  end

  test 'the last battle time is the newest from either table' do
    PokemonBattleLog.create!(attacker: @user, defender: User.find(101), winner: @user, updated_at: 1.hour.ago)
    battle = create_pokemon_battle(attacker: @rival, defender: @user, created_at: 3.hours.ago)

    assert_in_delta 1.hour.ago, @user.last_battle_at, 1.second
    assert_in_delta battle.created_at, @rival.last_battle_at, 1.second
  end

  test 'victories and totals add both tables' do
    PokemonBattleLog.create!(attacker: @user, defender: @rival, winner: @user)
    create_pokemon_battle(attacker: @rival, defender: @user, winner: @rival)
    create_pokemon_battle(attacker: @user, defender: @rival, winner: @user)

    assert_equal [2, 3], [@user.battle_victory_count, @user.battle_total_count]
  end
end
