# frozen_string_literal: true

# Deploy B for Glicko-2: the running code ignores the 0–100 rating since 20261008100000. `down` brings it back from
# the Glicko rating with the inverse of that migration's carry (1500 → 50, 12 points per old point, clamped).
class DropTrainerProfilesRating < ActiveRecord::Migration[8.1]
  def up
    change_table :trainer_profiles, bulk: true do |t|
      t.remove_index name: 'index_trainer_profiles_on_rank'
      t.remove :rating
    end
  end

  def down
    add_column :trainer_profiles, :rating, :integer, default: 50, null: false, after: :pinned_until
    execute 'UPDATE trainer_profiles SET rating = LEAST(100, GREATEST(0, ROUND(50 + ((glicko_rating - 1500) / 12))))'
    add_index :trainer_profiles, %i[rating user_id], order: { rating: :desc }, name: 'index_trainer_profiles_on_rank'
  end
end
