class CreateFictionRatings < ActiveRecord::Migration[8.0]
  def change
    create_table :fiction_ratings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :fiction, null: false, foreign_key: true
      t.integer :rating, null: false, limit: 1

      t.timestamps
    end

    add_index :fiction_ratings, [:user_id, :fiction_id], unique: true, name: 'index_fiction_ratings_on_user_and_fiction'
    add_check_constraint :fiction_ratings, 'rating >= 1 AND rating <= 5', name: 'check_rating_range'
  end
end
