class CreateBookshelves < ActiveRecord::Migration[8.0]
  def change
    create_table :bookshelves do |t|
      t.string :title, null: false
      t.text :description, null: false
      t.references :user, null: false, foreign_key: true
      t.integer :views, default: 0

      t.timestamps
    end
  end
end
