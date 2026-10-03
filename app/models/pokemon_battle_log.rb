# frozen_string_literal: true

# Battles fought before PokemonBattle. Converted to legacy PokemonBattle rows and no longer read; kept until the table
# is dropped so User#destroy can delete a user's rows (the foreign keys do not cascade).
class PokemonBattleLog < ApplicationRecord
  belongs_to :attacker, class_name: 'User', inverse_of: :attacker_battle_logs
  belongs_to :defender, class_name: 'User', inverse_of: :defender_battle_logs
  belongs_to :winner, class_name: 'User'
end
