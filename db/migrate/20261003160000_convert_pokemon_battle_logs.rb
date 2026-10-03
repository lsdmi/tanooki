# frozen_string_literal: true

# Copies every pokemon_battle_logs row into pokemon_battles as outcome only (engine_version 0: no teams, events, seed
# or rating deltas). The HTML bodies are not kept; `rake pokemons:purge_legacy_logs` deletes them afterwards. The
# log's updated_at is when the battle finished, which is what the battle cooldown counted from.
class ConvertPokemonBattleLogs < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      INSERT INTO pokemon_battles (attacker_id, defender_id, winner_id, seed, engine_version, attacker_team,
        defender_team, events, rating_delta_attacker, rating_delta_defender, created_at)
      SELECT attacker_id, defender_id, winner_id, 0, 0, JSON_ARRAY(), JSON_ARRAY(), JSON_ARRAY(), 0, 0, updated_at
      FROM pokemon_battle_logs ORDER BY id
    SQL
  end

  def down
    execute 'DELETE FROM pokemon_battles WHERE engine_version = 0'
  end
end
