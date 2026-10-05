# frozen_string_literal: true

# New battles run on engine version 2 (base_hp / base_attack); version 1 replays read power_level from the team
# snapshots stored on pokemon_battles, not from this column.
class RemovePowerLevelFromPokemons < ActiveRecord::Migration[8.1]
  def change
    remove_column :pokemons, :power_level, :integer
  end
end
