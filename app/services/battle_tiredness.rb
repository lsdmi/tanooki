# frozen_string_literal: true

# Maps post-battle experience gap to a tiredness penalty value.
class BattleTiredness
  def self.calculate(attacker, defender)
    difference = attacker - defender

    if difference >= Pokemons::Battle::Constants::TIREDNESS_THRESHOLDS[:overwhelming_victory]
      Pokemons::Battle::Constants::TIREDNESS_VALUES[:overwhelming_victory]
    elsif difference >= Pokemons::Battle::Constants::TIREDNESS_THRESHOLDS[:significant_victory]
      Pokemons::Battle::Constants::TIREDNESS_VALUES[:significant_victory]
    else
      Pokemons::Battle::Constants::TIREDNESS_VALUES[:close_victory]
    end
  end
end
