# frozen_string_literal: true

require 'test_helper'

module Pokemons
  class BaseStatsTest < ActiveSupport::TestCase
    test 'covers every Gen 1 dex number with stats in range' do
      assert_equal (1..151).to_a, BaseStats.table.keys.sort
      assert(BaseStats.table.values.flat_map(&:values).all? { |stat| stat.is_a?(Integer) && stat.between?(1, 255) })
    end

    test 'attack is the stronger of the physical and special one' do
      assert_equal({ hp: 55, attack: 135 }, BaseStats.for(65), 'Alakazam attacks with Special Attack')
      assert_equal({ hp: 160, attack: 110 }, BaseStats.for(143), 'Snorlax attacks with Attack')
    end

    test 'accepts a string dex number and returns nil for an unknown one' do
      assert_equal({ hp: 250, attack: 35 }, BaseStats.for('113'))
      assert_nil BaseStats.for(152)
      assert_nil BaseStats.for(nil)
    end
  end
end
