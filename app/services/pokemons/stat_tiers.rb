# frozen_string_literal: true

module Pokemons
  # The words the card shows for a species, never its numbers. Might: seven tiers by how often the species beats the
  # rest one on one (config/pokemon_might.yml, written by pokemons:might), each tier 10 points of win rate wide, so the
  # top one holds a handful. Stamina (HP) and strike (attack): fifths among the species in BaseStats.
  module StatTiers
    PATH = Rails.root.join('config/pokemon_might.yml')
    # Lowest win rate of might tiers 2 to 7.
    MIGHT_FLOORS = [0.25, 0.35, 0.45, 0.55, 0.65, 0.75].freeze
    FIFTHS = 5

    Tiers = Data.define(:might, :stamina, :strike)

    # +species+ responds to dex_id, base_hp and base_attack (a Pokemon or a BalanceReport::Species).
    def self.for(species)
      Tiers.new(might: might_tier(win_rate(species)), stamina: fifth(:hp, species.base_hp),
                strike: fifth(:attack, species.base_attack))
    end

    def self.might_tier(rate)
      MIGHT_FLOORS.count { |floor| rate >= floor } + 1
    end

    # A species missing from the file takes the rate of the one closest in HP x attack.
    def self.win_rate(species)
      win_rates.fetch(species.dex_id.to_i) do
        product = Math.log(species.base_hp * species.base_attack)
        win_rates.min_by { |other, _| (Math.log(official_product(other)) - product).abs }.last
      end
    end

    def self.win_rates
      @win_rates ||= YAML.load_file(PATH).freeze
    end

    def self.official_product(dex_id)
      BaseStats.for(dex_id).values_at(:hp, :attack).inject(:*)
    end

    # Share of species strictly below +value+, in fifths.
    def self.fifth(stat, value)
      sorted = ranked.fetch(stat)
      below = sorted.bsearch_index { |other| other >= value } || sorted.size
      [(below * FIFTHS / sorted.size) + 1, FIFTHS].min
    end

    def self.ranked
      @ranked ||= begin
        stats = BaseStats.table.keys.map { |dex_id| BaseStats.for(dex_id) }
        { hp: stats.pluck(:hp).sort.freeze, attack: stats.pluck(:attack).sort.freeze }.freeze
      end
    end
  end
end
