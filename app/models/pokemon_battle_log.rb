# frozen_string_literal: true

# Record of a Pokemon battle between two users.
class PokemonBattleLog < ApplicationRecord
  belongs_to :attacker, class_name: 'User', inverse_of: :attacker_battle_logs
  belongs_to :defender, class_name: 'User', inverse_of: :defender_battle_logs
  belongs_to :winner, class_name: 'User'

  has_rich_text :details

  POTENTIAL_FRAUD_ALERT = 'Ця сутичка наразі неможлива. Спробуйте пізніше чи оберіть іншого опонента.'
end
