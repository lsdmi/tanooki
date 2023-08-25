class AddExtraPokemonFields < ActiveRecord::Migration[7.0]
  def change
    change_table :pokemons do |t|
      t.references :ancestor, foreign_key: { to_table: :pokemons }, after: :rarity
      t.references :descendant, foreign_key: { to_table: :pokemons }, after: :ancestor_id
      t.integer :descendant_level, after: :descendant_id
    end

    change_table :user_pokemons do |t|
      t.integer :current_level, default: 0, after: :user_id
    end
  end
end
