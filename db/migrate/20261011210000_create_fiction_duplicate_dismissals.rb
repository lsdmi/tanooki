# frozen_string_literal: true

# Pairs an admin marked as different works, so the duplicate list does not offer them again.
class CreateFictionDuplicateDismissals < ActiveRecord::Migration[8.1]
  def change
    create_table :fiction_duplicate_dismissals do |t|
      t.references :fiction, null: false, foreign_key: { on_delete: :cascade }
      t.references :other_fiction, null: false, foreign_key: { to_table: :fictions, on_delete: :cascade }
      t.references :user, foreign_key: { on_delete: :nullify }
      t.timestamps
    end

    add_index :fiction_duplicate_dismissals, %i[fiction_id other_fiction_id],
              unique: true, name: 'index_fiction_duplicate_dismissals_on_pair'
    add_check_constraint :fiction_duplicate_dismissals, 'fiction_id < other_fiction_id',
                         name: 'fiction_duplicate_dismissals_ordered_pair'
  end
end
