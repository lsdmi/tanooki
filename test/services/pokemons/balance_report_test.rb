# frozen_string_literal: true

require 'test_helper'

module Pokemons
  class BalanceReportTest < ActiveSupport::TestCase
    SPECIES = [
      BalanceReport::Species.new(name: 'Weak', power_level: 1, rarity: 1, types: %w[Звичайний]),
      BalanceReport::Species.new(name: 'Mid', power_level: 3, rarity: 3, types: %w[Вогняний Повітряний]),
      BalanceReport::Species.new(name: 'Strong', power_level: 5, rarity: 5, types: %w[Водяний])
    ].freeze

    test 'reads the species catalogue with power level, rarity and types' do
      first = BalanceReport.species.find { |species| species.name == 'First' }

      assert_equal [4, %w[Звичайний]], [first.power_level, first.types]
      assert_includes 1..5, first.rarity
    end

    test 'runs N mirror matches per trait without touching the database' do
      report = report(battles: 20)

      assert_no_queries { report.traits }
      assert_equal Engine::Traits.registry.keys.sort, report.traits.map(&:label).sort
      assert(report.traits.all? { |row| row.total == 20 && row.wins.between?(0, 20) })
    end

    test 'the same seed gives the same numbers, whatever order the tables are read in' do
      first = report.tap(&:traits).types
      second = report.types

      assert_equal first, second
      assert_equal report.traits, report.tap(&:rarities).traits
    end

    test 'every round counts once for the winner and once for the loser' do
      report = report()
      rounds = report.power_levels.sum(&:wins)

      assert_operator rounds, :>=, report.battles
      assert_equal rounds * 2, report.rarities.sum(&:total)
      assert_equal [1, 3, 5], report.rarities.map(&:label)
    end

    test 'renders Markdown tables and names the traits over target' do
      report = report()
      over = BalanceReport::Row.new(label: 'brave', wins: 9, total: 10)
      markdown = report.stub(:unbalanced_traits, [over]) { BalanceReport::Markdown.render(report) }

      assert_includes markdown, 'over target: brave'
      assert_includes markdown, '| Rarity | Won | Fought | Win rate |'
      assert_match(/^\| super_rare \| \d+ \| \d+ \| \d+\.\d% \|$/, markdown)
    end

    private

    def report(battles: 30, seed: 7)
      BalanceReport.new(battles:, seed:, species: SPECIES)
    end
  end
end
