# frozen_string_literal: true

# The game state lives in trainer_profiles. Before the drop, whatever the old code wrote to users while the previous
# deploy rolled out is carried over: backfilled profiles the app has not written since (created at the backfill
# time, updated_at = created_at) take the users values again, and users without a profile get one. Profiles the app
# created later keep their values: those users rows hold only the old column defaults.
class DropTrainerColumnsFromUsers < ActiveRecord::Migration[8.1]
  LAST_BATTLES = <<~SQL.squish
    SELECT user_id, MAX(created_at) AS last_battle_at
    FROM (SELECT attacker_id AS user_id, created_at FROM pokemon_battles
          UNION ALL SELECT defender_id, created_at FROM pokemon_battles) AS sides
    GROUP BY user_id
  SQL

  REMERGE = <<~SQL.squish
    UPDATE trainer_profiles
    JOIN (SELECT MIN(created_at) AS created_at FROM trainer_profiles) AS backfill
      ON trainer_profiles.created_at = backfill.created_at
    JOIN users ON users.id = trainer_profiles.user_id
    LEFT JOIN (#{LAST_BATTLES}) AS battles ON battles.user_id = users.id
    SET trainer_profiles.rating = COALESCE(users.battle_win_rate, 50),
        trainer_profiles.last_catch_at = users.pokemon_last_catch,
        trainer_profiles.last_training_at = users.pokemon_last_training,
        trainer_profiles.last_battle_at = battles.last_battle_at,
        trainer_profiles.pinned_opponent_id = users.pinned_opponent_id,
        trainer_profiles.pinned_until = users.pinned_until,
        trainer_profiles.opponent_rerolled_at = users.opponent_rerolled_at
    WHERE trainer_profiles.updated_at = trainer_profiles.created_at
  SQL

  INSERT_MISSING = <<~SQL.squish
    INSERT INTO trainer_profiles (user_id, rating, last_catch_at, last_training_at, last_battle_at, pinned_opponent_id,
                                  pinned_until, opponent_rerolled_at, created_at, updated_at)
    SELECT users.id, COALESCE(users.battle_win_rate, 50), users.pokemon_last_catch, users.pokemon_last_training,
           battles.last_battle_at, users.pinned_opponent_id, users.pinned_until, users.opponent_rerolled_at,
           UTC_TIMESTAMP(6), UTC_TIMESTAMP(6)
    FROM users
    LEFT JOIN trainer_profiles ON trainer_profiles.user_id = users.id
    LEFT JOIN (#{LAST_BATTLES}) AS battles ON battles.user_id = users.id
    WHERE trainer_profiles.id IS NULL
  SQL

  RESTORE = <<~SQL.squish
    UPDATE users
    JOIN trainer_profiles ON trainer_profiles.user_id = users.id
    SET users.battle_win_rate = trainer_profiles.rating,
        users.pokemon_last_catch = trainer_profiles.last_catch_at,
        users.pokemon_last_training = trainer_profiles.last_training_at,
        users.pinned_opponent_id = trainer_profiles.pinned_opponent_id,
        users.pinned_until = trainer_profiles.pinned_until,
        users.opponent_rerolled_at = trainer_profiles.opponent_rerolled_at
  SQL

  def up
    execute REMERGE
    execute INSERT_MISSING

    change_table :users, bulk: true do |t|
      t.remove_index name: 'index_users_on_dex_rank'
      t.remove :battle_win_rate, :pokemon_last_catch, :pokemon_last_training, :pinned_opponent_id, :pinned_until,
               :opponent_rerolled_at
    end
  end

  def down
    change_table :users, bulk: true do |t|
      t.integer :battle_win_rate, default: 50
      t.datetime :pokemon_last_catch, default: '2023-09-18 02:18:35'
      t.datetime :pokemon_last_training, default: '2023-11-02 02:58:41'
      t.bigint :pinned_opponent_id
      t.datetime :pinned_until, :opponent_rerolled_at
      t.index %i[battle_win_rate id], order: { battle_win_rate: :desc }, name: 'index_users_on_dex_rank'
    end
    execute RESTORE
  end
end
