# frozen_string_literal: true

# A fiction review is a top-level comment on a fiction that its author marked as a review. The text stays in
# `comments`; this table only points at it, so MySQL can enforce one review per (user, fiction).
# `comments.spoiler` lets any comment be collapsed behind a spoiler warning.
class CreateFictionReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :fiction_reviews, charset: 'utf8mb4', collation: 'utf8mb4_0900_ai_ci' do |t|
      t.references :comment, null: false, index: { unique: true }, foreign_key: { on_delete: :cascade }
      t.references :user, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.references :fiction, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.timestamps
      t.index %i[user_id fiction_id], unique: true, name: 'index_fiction_reviews_on_user_and_fiction'
      t.index %i[fiction_id created_at], name: 'index_fiction_reviews_on_fiction_and_created_at'
    end

    add_column :fictions, :reviews_count, :integer, default: 0, null: false, after: :comments_count
    add_column :comments, :spoiler, :boolean, default: false, null: false, after: :content
  end
end
