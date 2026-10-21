# frozen_string_literal: true

# Reader list filters. Rating cap is one row per account; hidden genres are a join so a deleted genre cleans up.
class CreateContentFilters < ActiveRecord::Migration[8.1]
  def change
    create_user_content_filters
    create_user_hidden_genres
  end

  private

  def create_user_content_filters
    create_table :user_content_filters do |t|
      t.references :user, null: false, index: { unique: true }, foreign_key: { on_delete: :cascade }
      t.integer :max_content_rating
      t.timestamps
    end
  end

  def create_user_hidden_genres
    create_table :user_hidden_genres do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.references :genre, null: false, foreign_key: { on_delete: :cascade }
      t.timestamps
    end

    add_index :user_hidden_genres, %i[user_id genre_id], unique: true
  end
end
