# frozen_string_literal: true

# Speeds Pokédex "seen" lookups: distinct pokemon_id per user.
class AddUserPokemonIndexOnEncounters < ActiveRecord::Migration[8.1]
  def change
    add_index :pokemon_encounters, %i[user_id pokemon_id],
              name: 'index_pokemon_encounters_on_user_id_and_pokemon_id'
  end
end
