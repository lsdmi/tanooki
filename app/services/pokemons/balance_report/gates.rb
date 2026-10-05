# frozen_string_literal: true

module Pokemons
  class BalanceReport
    # The balance gates new battles must pass before switching engine versions (Pokémon rebuild doc, 2.5). +measure+
    # reads a report and returns a rate, a [min, max] pair of rates, a count, or nil when the version has no such
    # thing; +passes+ judges it.
    module Gates
      Gate = Data.define(:label, :target, :measure, :passes)

      def self.within(low, high) = ->(value) { value.between?(low, high) }
      def self.at_most(high) = ->(value) { value <= high }
      def self.at_least(low) = ->(value) { value >= low }

      ALL = [
        Gate.new('Trait mirror matches', 'every trait 45–55%', ->(r) { r.traits.map(&:win_rate).minmax },
                 ->((low, high)) { low >= 0.45 && high <= 0.55 }),
        Gate.new('Weakest might tier, rounds won', '≥ 15%', ->(r) { r.might_tiers.min_by(&:label).win_rate },
                 at_least(0.15)),
        Gate.new('Attacker win rate, team battles', '48–52%', lambda(&:attacker_win_rate), within(0.48, 0.52)),
        Gate.new('Swapping sides, same seed, mirrors', '100%', lambda(&:mirror_rate), at_least(1.0)),
        Gate.new('Bottom-quartile species vs the field', '20–35%', ->(r) { r.duels.bottom_quartile },
                 within(0.2, 0.35)),
        Gate.new('Top-quartile species vs the field', '≤ 72%', ->(r) { r.duels.top_quartile }, at_most(0.72)),
        Gate.new('Weaker species wins (strength gap > 1.3×)', '15–30%', ->(r) { r.duels.upsets }, within(0.15, 0.3)),
        Gate.new('Lopsided species pairs (one side wins > 90%)', '≤ 25%', ->(r) { r.duels.lopsided }, at_most(0.25)),
        Gate.new('Type edge between near-equal species', '62–75%', ->(r) { r.duels.type_edge }, within(0.62, 0.75)),
        Gate.new('First striker wins the round', '≤ 55%', ->(r) { r.duels.first_striker }, at_most(0.55)),
        Gate.new('Hits per round, median (both sides)', '4–8', ->(r) { r.duels.hits_per_round }, within(4, 8)),
        Gate.new('Same species, experience 100 vs 0', '80–92%', ->(r) { r.duels.experience }, within(0.8, 0.92)),
        Gate.new('Card might, mean drift (else run pokemons:might)', '≤ 3 points', ->(r) { Field.drift(r) },
                 at_most(0.03))
      ].freeze

      # Whether +value+ passes +gate+; a version without the measure fails it.
      def self.pass?(gate, value)
        !value.nil? && gate.passes.call(value)
      end
    end
  end
end
