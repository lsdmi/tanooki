class CreateTranslationRequestVotes < ActiveRecord::Migration[8.0]
  def change
    create_table :translation_request_votes do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.references :translation_request, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    # Ensure one vote per user per translation request
    add_index :translation_request_votes, [:user_id, :translation_request_id],
              unique: true, name: 'index_tr_votes_on_user_and_request'
  end
end
