class AddMorePokemonFields < ActiveRecord::Migration[7.0]
  def change
    change_table :user_pokemons do |t|
      t.integer :battle_experience, default: 0, after: :current_level
      t.string :character, after: :battle_experience
    end
  end
end
