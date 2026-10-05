# frozen_string_literal: true

# The game's per-user state moves off users (dropped there in a later deploy). Every user gets a row: each account
# owns a starter Pokémon. created_at = updated_at marks a row the app has not written since this backfill, so the
# drop migration can copy over anything the old code wrote to users during the deploy.
class CreateTrainerProfiles < ActiveRecord::Migration[8.1]
  # last_battle_at counts both sides, like the OR query it replaces.
  BACKFILL = <<~SQL.squish
    INSERT INTO trainer_profiles (user_id, rating, last_catch_at, last_training_at, last_battle_at, pinned_opponent_id,
                                  pinned_until, opponent_rerolled_at, created_at, updated_at)
    SELECT users.id, COALESCE(users.battle_win_rate, 50), users.pokemon_last_catch, users.pokemon_last_training,
           battles.last_battle_at, users.pinned_opponent_id, users.pinned_until, users.opponent_rerolled_at,
           UTC_TIMESTAMP(6), UTC_TIMESTAMP(6)
    FROM users
    LEFT JOIN (SELECT user_id, MAX(created_at) AS last_battle_at
               FROM (SELECT attacker_id AS user_id, created_at FROM pokemon_battles
                     UNION ALL SELECT defender_id, created_at FROM pokemon_battles) AS sides
               GROUP BY user_id) AS battles ON battles.user_id = users.id
  SQL

  def change
    create_table :trainer_profiles, charset: 'utf8mb4', collation: 'utf8mb4_0900_ai_ci' do |t|
      t.references :user, null: false, index: { unique: true }, foreign_key: { on_delete: :cascade }
      t.integer :rating, null: false, default: 50
      t.datetime :last_catch_at, :last_training_at, :last_battle_at
      t.bigint :pinned_opponent_id
      t.datetime :pinned_until, :opponent_rerolled_at
      t.timestamps
      t.index %i[rating user_id], order: { rating: :desc }, name: 'index_trainer_profiles_on_rank'
    end

    reversible { |direction| direction.up { execute BACKFILL } }
  end
end
