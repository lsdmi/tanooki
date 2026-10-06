# frozen_string_literal: true

require 'test_helper'

module Pokemons
  class BalanceReportTest < ActiveSupport::TestCase
    include PokemonBattleHelpers
    include PokemonEvolutionLineHelpers

    SPECIES = [
      BalanceReport::Species.new(id: 1, dex_id: 129, name: 'Weak', rarity: 1, types: %w[normal], base_hp: 20,
                                 base_attack: 15),
      BalanceReport::Species.new(id: 2, dex_id: 25, name: 'Mid', rarity: 3, types: %w[fire flying],
                                 base_hp: 60, base_attack: 80),
      BalanceReport::Species.new(id: 3, dex_id: 143, name: 'Strong', rarity: 5, types: %w[water], base_hp: 160,
                                 base_attack: 110)
    ].freeze

    test 'reads the species catalogue with might tier, rarity, types and base stats' do
      first = BalanceReport::Species.catalogue.find { |species| species.name == 'First' }

      read = [first.dex_id, first.might, first.types, first.base_hp, first.base_attack]

      assert_equal [1, 2, %w[normal], 45, 65], read
      assert_includes 1..5, first.rarity
    end

    test 'trainers are those who battled recently, or everyone with a full team when too few did' do
      5.times do |index|
        UserPokemon.create!(user: users(:user_one), pokemon: create_line_root("Line #{index}", dex_id: 10 + index),
                            character: :brave, battle_experience: 40)
      end
      species = BalanceReport::Species.catalogue
      create_pokemon_battle(attacker: users(:user_one), defender: User.find(2))
      full_teams = BalanceReport::Trainers.load(species)
      recent = BalanceReport::Trainers.load(species, min_trainers: 2)

      assert_equal [6], full_teams.map(&:size)
      assert_equal [['First', 1, 'lucky'], ['Line 0', 40, 'brave']], named(full_teams).first.first(2)
      assert_equal [6, 1], recent.map(&:size)
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
      rounds = report.might_tiers.sum(&:wins)

      assert_operator rounds, :>=, report.battles
      assert_equal rounds * 2, report.rarities.sum(&:total)
      assert_equal [1, 3, 5], report.rarities.map(&:label)
    end

    test 'team battles field the trainers given' do
      trainers = [[[SPECIES.first, 50, 'brave']], [[SPECIES.last, 0, nil], [SPECIES.first, 10, 'lucky']]]
      report = BalanceReport.new(battles: 20, seed: 7, species: SPECIES, trainers:)

      assert_equal [1, 5], report.rarities.map(&:label)
    end

    test 'version 2 battles mirror when the sides swap; version 1 ones do not' do
      assert_in_delta 1.0, report(version: 2).mirror_rate
      assert_operator report(version: 1).mirror_rate, :<, 0.5
    end

    test 'renders the gates for every version, then the last one in detail' do
      markdown = BalanceReport::Markdown.render([report(version: 1), report(version: 2)])

      assert_includes markdown, '| Measure | Version 1 | Version 2 | Target | Verdict |'
      assert_match(/^\| First striker wins the round \| — \| \d+\.\d% \| ≤ 55% \| (pass|FAIL) \|$/, markdown)
      assert_includes markdown, 'Engine v2, 30 battles per table'
    end

    test 'measures how far the card might file drifted, for today\'s version only' do
      assert_nil BalanceReport::Field.drift(report(version: 1))
      assert_includes 0.0..1.0, BalanceReport::Field.drift(report(version: 2))
    end

    test 'names the traits over target' do
      report = report()
      over = BalanceReport::Row.new(label: 'brave', wins: 9, total: 10)
      markdown = report.stub(:unbalanced_traits, [over]) { BalanceReport::Markdown.render([report]) }

      assert_includes markdown, 'over target: brave'
      assert_match(/^\| super_rare \| \d+ \| \d+ \| \d+\.\d% \|$/, markdown)
    end

    private

    def report(battles: 30, seed: 7, version: 1)
      BalanceReport.new(battles:, seed:, version:, species: SPECIES, trainers: [])
    end

    def named(trainers)
      trainers.map do |collection|
        collection.map { |species, experience, character| [species.name, experience, character] }
      end
    end
  end
end
