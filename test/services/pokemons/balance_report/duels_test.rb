# frozen_string_literal: true

require 'test_helper'

module Pokemons
  class BalanceReport
    class DuelsTest < ActiveSupport::TestCase
      SPECIES = [[20, 15, %w[water]], [40, 45, %w[flying]], [35, 55, %w[electric]], [60, 90, %w[electric]],
                 [78, 109, %w[fire]], [80, 100, %w[grass]], [91, 134, %w[dragon]],
                 [160, 110, %w[normal]]].each_with_index.map do |(hp, attack, types), index|
        Species.new(id: index + 1, dex_id: index + 1, name: "S#{index}", rarity: 1, types:, base_hp: hp,
                    base_attack: attack)
      end.freeze

      test 'measures every rate between 0 and 1 without touching the database' do
        duels = duels(version: 2)
        measures = %i[bottom_quartile top_quartile upsets type_edge first_striker lopsided experience]
        rates = assert_no_queries { measures.map { duels.public_send(it) } }

        assert_empty rates.grep_v(0..1)
      end

      test 'the same seed gives the same numbers, whatever order they are read in' do
        first = duels.tap(&:experience).upsets
        second = duels.upsets

        assert_equal first, second
        assert_equal duels.experience, duels.tap(&:lopsided).experience
      end

      test 'the strong quarter wins more than the weak one' do
        duels = duels(version: 2)

        assert_operator duels.top_quartile, :>, duels.bottom_quartile
      end

      test 'version 1 has no initiative and settles a round in one comparison' do
        assert_nil duels(version: 1).first_striker
        assert_equal 1, duels(version: 1).hits_per_round
        assert_operator duels(version: 2).hits_per_round, :>, 1
      end

      private

      def duels(version: 1, battles: 200, seed: 3)
        Duels.new(version:, species: SPECIES, battles:, seed:)
      end
    end
  end
end
