# frozen_string_literal: true

# Battles fought before PokemonBattle, with the log as rendered HTML. Read-only; Phase 2.4 converts and drops them.
class PokemonBattleLog < ApplicationRecord
  belongs_to :attacker, class_name: 'User', inverse_of: :attacker_battle_logs
  belongs_to :defender, class_name: 'User', inverse_of: :defender_battle_logs
  belongs_to :winner, class_name: 'User'

  has_rich_text :details
end
