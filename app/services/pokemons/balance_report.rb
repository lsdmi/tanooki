# frozen_string_literal: true

module Pokemons
  # Balance numbers for one engine version (rake pokemons:simulate[N]). Team battles use real collections (Trainers;
  # random lineups when there are none). Traits: N mirror matches each, an all-T team against the same Pokémon with
  # the other traits. Types, rarity and might: rounds won in N team battles. Species measures come from Duels. Same
  # seed, same species and trainers, same report.
  class BalanceReport
    Row = Data.define(:label, :wins, :total) do
      def win_rate
        total.zero? ? 0.0 : wins.fdiv(total)
      end
    end
    # One team battle: the teams, the seed it was fought with, and the species by combatant id.
    Battle = Data.define(:attacker, :defender, :seed, :result, :species)

    TRAIT_TARGET = 0.55
    EXPERIENCE = 0..100
    LINEUP_SIZES = 1..6
    DEFENDER_IDS = 1_000_001
    MIRROR_CHECKS = 200

    attr_reader :battles, :version, :species

    def initialize(battles:, seed:, version: Engine::VERSION, species: Species.catalogue,
                   trainers: Trainers.load(species))
      @battles = battles
      @seed = seed
      @version = version
      @simulator = Engine.simulator(version)
      @species = species
      @trainers = trainers
      @characters = Engine::Traits.registry.keys
    end

    def duels
      @duels ||= Duels.new(version:, species: @species, battles:, seed: @seed + 2)
    end

    # Each section rolls from its own generator, so reading them in any order gives the same numbers.
    def traits
      @traits ||= begin
        rng = Random.new(@seed)
        @characters.map { |trait| trait_row(trait, rng) }.sort_by { |row| -row.win_rate }
      end
    end

    def unbalanced_traits
      traits.select { |row| row.win_rate > TRAIT_TARGET }
    end

    def types = tally { |species| species.types.uniq }
    def rarities = tally { |species| [species.rarity] }
    def might_tiers = tally { |species| [species.might] }

    def attacker_win_rate
      team_battles.count { |battle| battle.result.attacker_won? }.fdiv(battles)
    end

    # Share of team battles that mirror when fought again with the sides swapped and the same seed.
    def mirror_rate
      checked = team_battles.first(MIRROR_CHECKS)
      checked.count { |battle| Mirror.mirrored?(battle, @simulator) }.fdiv(checked.size)
    end

    private

    def trait_row(trait, rng)
      wins = Array.new(battles) { |i| mirror_win?(trait, rng, attacking: i.even?) }.count(true)
      Row.new(label: trait, wins:, total: battles)
    end

    def mirror_win?(trait, rng, attacking:)
      lineup = lineup(rng)
      own = team(lineup, 1) { trait }
      opponent = team(lineup, DEFENDER_IDS) { (@characters - [trait]).sample(random: rng) }
      simulate(*(attacking ? [own, opponent] : [opponent, own]), rng).attacker_won? == attacking
    end

    def team_battles
      @team_battles ||= begin
        rng = Random.new(@seed + 1)
        Array.new(battles) { team_battle(rng) }
      end
    end

    def team_battle(rng)
      lineups = { 1 => lineup(rng), DEFENDER_IDS => lineup(rng) }
      attacker, defender = lineups.map do |id, lineup|
        team(lineup, id) { |own| own || @characters.sample(random: rng) }
      end
      seed = rng.rand(1 << 62)
      Battle.new(attacker:, defender:, seed:, result: simulate(attacker, defender, Random.new(seed)),
                 species: species_by_combatant(lineups))
    end

    # A random trainer's collection, or a random lineup of 1–6 species with random experience and no trait.
    def lineup(rng)
      return @trainers.sample(random: rng) if @trainers.any?

      Array.new(rng.rand(LINEUP_SIZES)) { [@species.sample(random: rng), rng.rand(EXPERIENCE), nil] }
    end

    # Yields each entry's own character; the block returns the one to fight with.
    def team(lineup, first_id)
      Engine::TeamSnapshot.new(trainer_id: first_id, combatants: lineup.each_with_index.map do |entry, index|
        species, experience, character = entry
        species.combatant(first_id + index, experience, yield(character))
      end)
    end

    def species_by_combatant(lineups)
      lineups.flat_map { |id, lineup| lineup.each_with_index.map { |(species, _), i| [id + i, species] } }.to_h
    end

    def simulate(attacker, defender, rng)
      @simulator.call(attacker:, defender:, rng:)
    end

    # Win rate per label over every round fought; a round counts once for the winner's labels and the loser's.
    def tally(&)
      wins = round_pairs.map(&:first).flat_map(&).tally
      totals = round_pairs.flatten.flat_map(&).tally
      totals.keys.sort.map { |label| Row.new(label:, wins: wins.fetch(label, 0), total: totals[label]) }
    end

    # [winner, loser] species of every round.
    def round_pairs
      @round_pairs ||= team_battles.flat_map do |battle|
        result = battle.result
        result.events_of(:round_started).zip(result.events_of(:fainted)).map do |start, fainted|
          loser = fainted.data[:combatant]
          battle.species.values_at((start.data.values_at(:attacker, :defender) - [loser]).first, loser)
        end
      end
    end
  end
end
