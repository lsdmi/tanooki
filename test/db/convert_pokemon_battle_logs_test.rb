# frozen_string_literal: true

require 'test_helper'
require Rails.root.join('db/migrate/20261003160000_convert_pokemon_battle_logs')

class ConvertPokemonBattleLogsTest < ActiveSupport::TestCase
  include PokemonBattleHelpers

  setup do
    @attacker = users(:user_one)
    @defender = users(:user_two)
    @finished_at = 3.days.ago.change(usec: 0)
  end

  test 'copies each log as an outcome-only legacy battle at the time it finished' do
    log = PokemonBattleLog.create!(attacker: @attacker, defender: @defender, winner: @defender,
                                   created_at: @finished_at - 1.minute, updated_at: @finished_at)

    migrate(:up)

    battle = PokemonBattle.legacy.sole

    assert_equal [log.attacker_id, log.defender_id, log.winner_id, @finished_at],
                 [battle.attacker_id, battle.defender_id, battle.winner_id, battle.created_at]
    assert_equal [0, [], [], [], 0, 0], [battle.seed, battle.attacker_team, battle.defender_team, battle.events,
                                         battle.rating_delta_attacker, battle.rating_delta_defender]
  end

  test 'down removes only the legacy rows' do
    PokemonBattleLog.create!(attacker: @attacker, defender: @defender, winner: @attacker)
    battle = create_pokemon_battle(attacker: @attacker, defender: @defender)
    migrate(:up)

    migrate(:down)

    assert_equal [battle], PokemonBattle.all.to_a
  end

  private

  def migrate(direction)
    ActiveRecord::Migration.suppress_messages { ConvertPokemonBattleLogs.new.migrate(direction) }
  end
end
