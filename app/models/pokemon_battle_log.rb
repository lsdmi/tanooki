# frozen_string_literal: true

class PokemonBattleLog < ApplicationRecord
  belongs_to :attacker, class_name: 'User'
  belongs_to :defender, class_name: 'User'
  belongs_to :winner, class_name: 'User'

  has_rich_text :details

  POTENTIAL_FRAUD_ALERT = 'Ця сутичка наразі неможлива. Спробуйте пізніше чи оберіть іншого опонента.'
end
