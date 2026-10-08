# frozen_string_literal: true

# Glicko-2 replaces the 0–100 rating. New columns rather than reusing `rating`: the code still running during the
# deploy clamps `rating` to 0..100. The current order carries over (50 → 1500, 12 points per old point); the
# deviation shrinks with the battles a trainer has fought, so a trainer with one battle is still unsure and one with a
# hundred is settled. The leaderboard ranks by glicko_floor (rating − 2·deviation). `rating` is dropped in a later
# deploy. A Glicko change can pass 127, so the per-battle deltas widen to smallint.
class AddGlickoToTrainerProfiles < ActiveRecord::Migration[8.1]
  def up
    add_glicko_columns
    carry_ratings
    add_index :trainer_profiles, %i[glicko_floor user_id], order: { glicko_floor: :desc },
                                                           name: 'index_trainer_profiles_on_glicko_rank'
    resize_deltas(2)
  end

  def down
    execute <<~SQL.squish
      UPDATE pokemon_battles
      SET rating_delta_attacker = LEAST(127, GREATEST(-128, rating_delta_attacker)),
          rating_delta_defender = LEAST(127, GREATEST(-128, rating_delta_defender))
    SQL
    resize_deltas(1)
    change_table :trainer_profiles, bulk: true do |t|
      t.remove_index name: 'index_trainer_profiles_on_glicko_rank'
      t.remove :glicko_floor, :glicko_rating, :glicko_deviation, :glicko_volatility
    end
  end

  private

  def add_glicko_columns
    change_table :trainer_profiles, bulk: true do |t|
      t.float :glicko_rating, limit: 53, null: false, default: 1500, after: :rating
      t.float :glicko_deviation, limit: 53, null: false, default: 350, after: :glicko_rating
      t.float :glicko_volatility, limit: 53, null: false, default: 0.06, after: :glicko_deviation
      t.virtual :glicko_floor, type: :float, limit: 53, as: 'glicko_rating - 2 * glicko_deviation', stored: true,
                               after: :glicko_volatility
    end
  end

  def carry_ratings
    execute <<~SQL.squish
      UPDATE trainer_profiles
      LEFT JOIN (
        SELECT user_id, COUNT(*) AS battles
        FROM (SELECT attacker_id AS user_id FROM pokemon_battles UNION ALL SELECT defender_id FROM pokemon_battles) sides
        GROUP BY user_id
      ) counts ON counts.user_id = trainer_profiles.user_id
      SET glicko_rating = 1500 + ((rating - 50) * 12),
          glicko_deviation = IF(counts.battles IS NULL, 350, GREATEST(90, 350 / SQRT(1 + (counts.battles / 4))))
    SQL
  end

  def resize_deltas(limit)
    change_table :pokemon_battles, bulk: true do |t|
      t.change :rating_delta_attacker, :integer, limit:, null: false
      t.change :rating_delta_defender, :integer, limit:, null: false
    end
  end
end
