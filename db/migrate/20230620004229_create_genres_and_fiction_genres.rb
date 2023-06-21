class CreateGenresAndFictionGenres < ActiveRecord::Migration[7.0]
  def change
    create_table :genres do |t|
      t.string :name
      t.timestamps
    end

    create_table :fiction_genres do |t|
      t.references :fiction, foreign_key: true
      t.references :genre, foreign_key: true
      t.timestamps
    end

    add_index :genres, :name
  end
end
