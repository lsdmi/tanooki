# frozen_string_literal: true

require 'test_helper'

module Pokemons
  module Engine
    class TypeChartTest < ActiveSupport::TestCase
      TABLE = { 'Fire' => { 'Fire' => 0.5, 'Grass' => 1.25 }, 'Grass' => { 'Fire' => 0.75, 'Grass' => 0.5 } }.freeze

      test 'looks up the effectiveness of one type against another' do
        chart = TypeChart.default

        assert_in_delta 1.25, chart.effectiveness('fire', 'grass')
        assert_in_delta 1.25, chart.effectiveness('water', 'fire')
        assert_in_delta 1.25, chart.effectiveness('grass', 'water')
      end

      test 'multiplies every pair of own and opposing types' do
        chart = TypeChart.new(TABLE)

        assert_in_delta 1.25 * 0.5, chart.multiplier(%w[Fire], %w[Grass Fire])
        assert_in_delta 0.75 * 0.5 * 0.5 * 1.25, chart.multiplier(%w[Grass Fire], %w[Fire Grass])
        assert_in_delta 1.0, chart.multiplier([], %w[Fire])
      end

      test 'is loaded once and frozen' do
        assert_same TypeChart.default, TypeChart.default
        assert_predicate TypeChart.default, :frozen?
      end

      test 'covers every Pokémon type' do
        assert_empty PokemonType.pluck(:key) - TypeChart.default.types
      end

      test 'every type in the chart has a label and a badge colour' do
        types = TypeChart.default.types

        assert_equal types.sort, I18n.t('pokemons.types').keys.map(&:to_s).sort
        assert_equal types.sort, Pokemons::StatsHelper::TYPE_COLORS.keys.sort
      end

      test 'refuses a chart with a missing pair' do
        error = assert_raises(TypeChart::Incomplete) { TypeChart.new(TABLE.merge('Grass' => { 'Grass' => 0.5 })) }

        assert_includes error.message, 'Grass -> Fire missing'
      end

      test 'refuses a chart that matches against an unknown type' do
        error = assert_raises(TypeChart::Incomplete) do
          TypeChart.new(TABLE.merge('Fire' => TABLE['Fire'].merge('Water' => 1.0)))
        end

        assert_includes error.message, 'Fire -> Water is not a type'
      end

      test 'refuses a chart with a zero or blank multiplier' do
        error = assert_raises(TypeChart::Incomplete) do
          TypeChart.new(TABLE.merge('Fire' => { 'Fire' => 0, 'Grass' => nil }))
        end

        assert_includes error.message, 'Fire -> Fire is 0.0'
        assert_includes error.message, 'Fire -> Grass is 0.0'
      end
    end
  end
end
