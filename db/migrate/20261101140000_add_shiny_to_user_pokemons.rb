# frozen_string_literal: true

class AddShinyToUserPokemons < ActiveRecord::Migration[8.0]
  def change
    add_column :user_pokemons, :shiny, :boolean, null: false, default: false, after: :pokemon_id
  end
end
