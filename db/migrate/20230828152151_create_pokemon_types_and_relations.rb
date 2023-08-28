class CreatePokemonTypesAndRelations < ActiveRecord::Migration[7.0]
  def change
    create_table :pokemon_types do |t|
      t.string :name, null: false
      t.timestamps
    end

    create_table :pokemon_type_relations do |t|
      t.references :pokemon, foreign_key: true, null: false
      t.references :pokemon_type, foreign_key: true, null: false
      t.timestamps
    end

    add_index :pokemon_type_relations, [:pokemon_id, :pokemon_type_id], unique: true
  end
end
