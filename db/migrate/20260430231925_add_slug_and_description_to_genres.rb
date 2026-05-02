class AddSlugAndDescriptionToGenres < ActiveRecord::Migration[8.0]
  def change
    add_column :genres, :slug, :string, null: true, after: :id
    add_column :genres, :description, :text, null: true, after: :name
    add_index :genres, :slug, unique: true
  end
end
