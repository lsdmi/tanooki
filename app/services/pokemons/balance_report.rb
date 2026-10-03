# frozen_string_literal: true

module Pokemons
  # Balance numbers from simulated battles between random teams of real species (rake pokemons:simulate[N]).
  # Traits: N mirror matches each, an all-T team against the same species and experience with the other traits.
  # Types, rarity and power: rounds won in N random battles. Same seed, same species, same report.
  class BalanceReport
    Species = Data.define(:name, :power_level, :rarity, :types)
    Row = Data.define(:label, :wins, :total) do
      def win_rate
        total.zero? ? 0.0 : wins.fdiv(total)
      end
    end

    TRAIT_TARGET = 0.55
    EXPERIENCE = 0..100
    DEFENDER_IDS = 1001

    attr_reader :battles

    def self.species
      Pokemon.includes(:pokemon_types).order(:id).map do |pokemon|
        Species.new(name: pokemon.name, power_level: pokemon.read_attribute(:power_level),
                    rarity: pokemon.read_attribute(:rarity), types: pokemon.types.map(&:name))
      end
    end

    def initialize(battles:, seed:, species: self.class.species, balance: Engine::BattleBalance::V1)
      @battles = battles
      @seed = seed
      @species = species
      @balance = balance
      @characters = Engine::Traits.registry.keys
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
    def power_levels = tally { |species| [species.power_level] }

    def attacker_win_rate
      random_battles.count { |result, _| result.attacker_won? }.fdiv(battles)
    end

    private

    def trait_row(trait, rng)
      wins = Array.new(battles) { |i| mirror_win?(trait, rng, attacking: i.even?) }.count(true)
      Row.new(label: trait, wins:, total: battles)
    end

    def mirror_win?(trait, rng, attacking:)
      lineup = random_lineup(rng)
      own = team(lineup, 1) { trait }
      opponent = team(lineup, DEFENDER_IDS) { (@characters - [trait]).sample(random: rng) }
      simulate(*(attacking ? [own, opponent] : [opponent, own]), rng).attacker_won? == attacking
    end

    # Each entry: the battle Result and the species by combatant id.
    def random_battles
      @random_battles ||= begin
        rng = Random.new(@seed + 1)
        Array.new(battles) { random_battle(rng) }
      end
    end

    def random_battle(rng)
      lineups = { 1 => random_lineup(rng), DEFENDER_IDS => random_lineup(rng) }
      attacker, defender = lineups.map { |id, lineup| team(lineup, id) { @characters.sample(random: rng) } }
      species = lineups.flat_map { |id, lineup| lineup.each_with_index.map { |(s, _), i| [id + i, s] } }.to_h
      [simulate(attacker, defender, rng), species]
    end

    def random_lineup(rng)
      Array.new(rng.rand(1..@balance.team_size)) { [@species.sample(random: rng), rng.rand(EXPERIENCE)] }
    end

    def team(lineup, first_id)
      Engine::TeamSnapshot.new(trainer_id: first_id, combatants: lineup.each_with_index.map do |(species, xp), index|
        Engine::Combatant.new(id: first_id + index, character: yield, power_level: species.power_level,
                              battle_experience: xp, types: species.types)
      end)
    end

    def simulate(attacker, defender, rng)
      Engine::Simulator.call(attacker:, defender:, rng:, balance: @balance)
    end

    # Win rate per label over every round fought; a round counts once for the winner's labels and the loser's.
    def tally(&)
      wins = round_pairs.map(&:first).flat_map(&).tally
      totals = round_pairs.flatten.flat_map(&).tally
      totals.keys.sort.map { |label| Row.new(label:, wins: wins.fetch(label, 0), total: totals[label]) }
    end

    def round_pairs
      @round_pairs ||= random_battles.flat_map do |result, species|
        result.events_of(:round_started).zip(result.events_of(:fainted)).map do |start, fainted|
          loser = fainted.data[:combatant]
          species.values_at((start.data.values_at(:attacker, :defender) - [loser]).first, loser)
        end
      end
    end
  end
end
