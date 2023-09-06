class AddIndexToPokemon < ActiveRecord::Migration[7.0]
  def change
    change_table :pokemons do |t|
      t.integer :dex_id, after: :id
    end
  end
end
