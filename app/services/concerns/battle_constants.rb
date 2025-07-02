# frozen_string_literal: true

module BattleConstants
  TIREDNESS_THRESHOLDS = {
    overwhelming_victory: 201,
    significant_victory: 101,
    close_victory: 0
  }.freeze

  TIREDNESS_VALUES = {
    overwhelming_victory: 0.15,
    significant_victory: 0.2,
    close_victory: 0.25
  }.freeze

  EXPERIENCE_THRESHOLDS = {
    high_gain: 10,
    low_gain: 15,
    confident_max: 115,
    regular_max: 100
  }.freeze

  EXPERIENCE_GAINS = {
    high: 2,
    low: 1,
    none: 0
  }.freeze
end
