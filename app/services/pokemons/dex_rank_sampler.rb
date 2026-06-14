# frozen_string_literal: true

module Pokemons
  # Samples a nearby dex rank for battle matchmaking.
  class DexRankSampler
    attr_reader :rank, :dex_overall

    def initialize(rank, dex_overall)
      @rank = rank
      @dex_overall = dex_overall
    end

    def call
      min_index = [rank - 5, 0].max
      max_index = [rank + 5, dex_overall - 1].min

      eligible_indices = (min_index..max_index).to_a - [rank]

      eligible_indices.sample
    end
  end
end
