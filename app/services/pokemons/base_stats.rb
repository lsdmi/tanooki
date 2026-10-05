# frozen_string_literal: true

module Pokemons
  # Official species stats by dex number (config/pokemon_base_stats.yml). Attack is the stronger of the physical and
  # special one, so special attackers (Alakazam, Gengar) are not weak in a game with a single attack stat.
  module BaseStats
    PATH = Rails.root.join('config/pokemon_base_stats.yml')

    def self.for(dex_id)
      stats = table[dex_id.to_i] or return
      { hp: stats.fetch('hp'), attack: [stats.fetch('attack'), stats.fetch('sp_attack')].max }
    end

    # Average of +stat+ (:hp or :attack) over every species in the file.
    def self.mean(stat)
      values = table.keys.map { |dex_id| self.for(dex_id).fetch(stat) }
      values.sum.fdiv(values.size)
    end

    def self.table
      @table ||= YAML.load_file(PATH).freeze
    end
  end
end
