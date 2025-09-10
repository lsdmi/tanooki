class CreateBookshelfFictions < ActiveRecord::Migration[8.0]
  def change
    create_table :bookshelf_fictions do |t|
      t.references :bookshelf, null: false, foreign_key: true
      t.references :fiction, null: false, foreign_key: true

      t.timestamps
    end

    add_index :bookshelf_fictions, [:bookshelf_id, :fiction_id], unique: true
  end
end
