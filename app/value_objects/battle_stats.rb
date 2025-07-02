# frozen_string_literal: true

class BattleStats
  attr_reader :id, :power, :luck, :experience, :tiredness, :type, :raw_total, :active

  def initialize(id:, power:, luck:, experience: 0, tiredness: 1.0, type: 1.0, raw_total: nil, active: true)
    @id = id
    @power = power
    @luck = luck
    @experience = experience
    @tiredness = tiredness
    @type = type
    @raw_total = raw_total || calculate_raw_total
    @active = active
  end

  def deactivate!
    @active = false
  end

  def add_tiredness(amount)
    @tiredness += amount
  end

  def reduce_tiredness(amount)
    @tiredness -= amount
  end

  def update_power(new_power)
    @power = new_power
    recalculate_raw_total
  end

  def update_luck(new_luck)
    @luck = new_luck
    recalculate_raw_total
  end

  def update_type(new_type)
    @type = new_type
  end

  def to_h
    {
      id: @id,
      power: @power,
      luck: @luck,
      experience: @experience,
      tiredness: @tiredness,
      type: @type,
      raw_total: @raw_total,
      active: @active
    }
  end

  def dup
    BattleStats.new(
      id: @id,
      power: @power,
      luck: @luck,
      experience: @experience,
      tiredness: @tiredness,
      type: @type,
      raw_total: @raw_total,
      active: @active
    )
  end

  private

  def calculate_raw_total
    (power + experience) * luck
  end

  def recalculate_raw_total
    @raw_total = calculate_raw_total
  end
end
