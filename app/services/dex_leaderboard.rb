# frozen_string_literal: true

class DexLeaderboard
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
