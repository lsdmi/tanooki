# frozen_string_literal: true

# A pair that already fought in the last 24 hours plays unranked: the battle counts for the cooldown and the history
# but changes no rating. Every battle so far was rated, and the code still running during the deploy rates every
# battle, so the default is true.
class AddRankedToPokemonBattles < ActiveRecord::Migration[8.1]
  def change
    add_column :pokemon_battles, :ranked, :boolean, null: false, default: true, after: :rating_delta_defender
  end
end
