# frozen_string_literal: true

class BattleTiredness
  def self.calculate(attacker, defender)
    difference = attacker - defender

    if difference >= BattleConstants::TIREDNESS_THRESHOLDS[:overwhelming_victory]
      BattleConstants::TIREDNESS_VALUES[:overwhelming_victory]
    elsif difference >= BattleConstants::TIREDNESS_THRESHOLDS[:significant_victory]
      BattleConstants::TIREDNESS_VALUES[:significant_victory]
    else
      BattleConstants::TIREDNESS_VALUES[:close_victory]
    end
  end
end
