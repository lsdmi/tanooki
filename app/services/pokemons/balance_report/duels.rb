# frozen_string_literal: true

module Pokemons
  class BalanceReport
    # One on one between species, without traits and at experience 0 unless experience is the measure: how much the
    # species, the type and striking first decide. Species are ranked by their official strength, sqrt(HP x attack).
    # Each measure rolls from its own generator, so reading them in any order gives the same numbers.
    class Duels
      UPSET_GAP = 1.3
      NEAR_EQUAL = 0.15
      LOPSIDED = 0.9
      REPEATS = 40
      VETERAN = 100

      # +pair+ fought as attacker (combatant 1) and defender (combatant 2).
      Duel = Data.define(:pair, :result) do
        def winner_id = result.attacker_won? ? 1 : 2
        def winner = pair[winner_id - 1]
        def weaker = pair.min_by(&:strength)
        def gap = pair.map(&:strength).max / pair.map(&:strength).min

        # The species whose types beat the other's, or nil when the chart is even.
        def favoured
          own, opponent = pair.map(&:types)
          chart = Engine::TypeChart.default
          mine = chart.multiplier(own, opponent)
          theirs = chart.multiplier(opponent, own)
          return if mine == theirs

          mine > theirs ? pair.first : pair.last
        end
      end

      def initialize(version:, species:, battles:, seed:)
        @simulator = Engine.simulator(version)
        @species = species
        @battles = battles
        @seed = seed
      end

      def bottom_quartile = quartile_win_rate(:bottom)
      def top_quartile = quartile_win_rate(:top)

      # Share of duels between species more than UPSET_GAP apart in strength that the weaker one wins; nil if none.
      def upsets
        share(field.reject { |duel| duel.gap < UPSET_GAP }) { |duel| duel.winner == duel.weaker }
      end

      # Share of duels between near-equal species with different type multipliers won by the side the chart favours;
      # nil if none.
      def type_edge
        edged = field.select { |duel| duel.gap < 1 + NEAR_EQUAL && duel.favoured }
        share(edged) { |duel| duel.winner == duel.favoured }
      end

      # nil when the version has no initiative.
      def first_striker
        starts = field.map { |duel| duel.result.events_of(:round_started).sole.data[:first_striker] }
        return if starts.any?(&:nil?)

        field.zip(starts).count { |duel, striker| duel.winner_id == striker }.fdiv(field.size)
      end

      # Median hits in a round, both sides counted; a round without hits (version 1) counts as one.
      def hits_per_round
        field.map { |duel| [duel.result.events_of(:hit).size, 1].max }.sort[field.size / 2]
      end

      # Share of species pairs that one side wins more than LOPSIDED of the time over REPEATS duels.
      def lopsided
        @lopsided ||= begin
          rng = Random.new(@seed + 1)
          pairs = Array.new([@battles / REPEATS, 10].max) { @species.sample(2, random: rng) }
          pairs.count { |pair| lopsided_pair?(pair, rng) }.fdiv(pairs.size)
        end
      end

      # The same species, experience VETERAN against 0, sides alternating.
      def experience
        @experience ||= begin
          rng = Random.new(@seed + 2)
          Array.new(@battles) do |i|
            species = @species.sample(random: rng)
            first_wins?(species, species, rng, experience: [VETERAN, 0], first_attacks: i.even?)
          end.count(true).fdiv(@battles)
        end
      end

      private

      def field
        @field ||= begin
          rng = Random.new(@seed)
          Array.new(@battles) do
            pair = @species.sample(2, random: rng)
            Duel.new(pair:, result: simulate(*pair.map.with_index(1) { |species, id| snapshot(species, id) }, rng))
          end
        end
      end

      def share(duels, &)
        duels.count(&).fdiv(duels.size) if duels.any?
      end

      # Rounds won by the quartile's species over the rounds they fought.
      def quartile_win_rate(quartile)
        members = quartile_members(quartile)
        games = field.flat_map(&:pair).count { |species| members.include?(species) }
        field.count { |duel| members.include?(duel.winner) }.fdiv(games)
      end

      def quartile_members(quartile)
        sorted = @species.map(&:strength).sort
        low = sorted[sorted.size / 4]
        high = sorted[(sorted.size * 3) / 4]
        @species.select { |species| quartile == :bottom ? species.strength <= low : species.strength >= high }.to_set
      end

      def lopsided_pair?(pair, rng)
        wins = Array.new(REPEATS) { |i| first_wins?(*pair, rng, experience: [0, 0], first_attacks: i.even?) }
        !wins.count(true).fdiv(REPEATS).between?(1 - LOPSIDED, LOPSIDED)
      end

      def first_wins?(first, second, rng, experience:, first_attacks:)
        own = snapshot(first, 1, experience.first)
        other = snapshot(second, 2, experience.last)
        first_attacks ? simulate(own, other, rng).attacker_won? : !simulate(other, own, rng).attacker_won?
      end

      def snapshot(species, id, experience = 0)
        Engine::TeamSnapshot.new(trainer_id: id, combatants: [species.combatant(id, experience)])
      end

      def simulate(attacker, defender, rng)
        @simulator.call(attacker:, defender:, rng:)
      end
    end
  end
end
