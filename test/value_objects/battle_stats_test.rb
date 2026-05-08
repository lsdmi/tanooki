# frozen_string_literal: true

require 'test_helper'

class BattleStatsTest < ActiveSupport::TestCase
  test 'initializes numeric defaults' do
    stats = BattleStats.new(power: 10, luck: 2.0)

    assert_equal 0, stats.experience

    assert_in_delta 1.0, stats.tiredness
    assert_in_delta 1.0, stats.type
  end

  test 'computes raw_total and defaults active' do
    stats = BattleStats.new(power: 10, luck: 2.0)

    assert_predicate stats, :active

    assert_in_delta 20.0, stats.raw_total
  end

  test 'accepts explicit raw_total and honors active false' do
    stats = BattleStats.new(power: 1, luck: 1, raw_total: 99, active: false)

    assert_in_delta 99.0, stats.raw_total
    assert_not stats.active
  end

  test 'deactivate! sets active to false' do
    stats = BattleStats.new(power: 1, luck: 1)

    stats.deactivate!

    assert_not stats.active
  end

  test 'update_power refreshes raw_total' do
    stats = BattleStats.new(power: 10, luck: 2.0, experience: 5)

    assert_in_delta 30.0, stats.raw_total

    stats.update_power(20)

    assert_in_delta 50.0, stats.raw_total
  end

  test 'update_luck refreshes raw_total' do
    stats = BattleStats.new(power: 10, luck: 2.0, experience: 5)

    stats.update_luck(3.0)

    assert_in_delta 45.0, stats.raw_total
  end

  test 'to_h includes all attributes' do
    stats = BattleStats.new(id: 1, power: 2, luck: 3, experience: 4, tiredness: 0.5, type: 1.2, active: true)

    h = stats.to_h

    assert_equal({ id: 1, power: 2, luck: 3, experience: 4, tiredness: 0.5, type: 1.2, raw_total: stats.raw_total,
                   active: true }, h)
  end

  test 'dup returns independent copy with same values' do
    original = BattleStats.new(power: 5, luck: 2.0, experience: 1)
    copy = original.dup

    assert_equal original.to_h, copy.to_h

    copy.add_tiredness(1)

    assert_operator copy.tiredness, :>, original.tiredness
  end
end
