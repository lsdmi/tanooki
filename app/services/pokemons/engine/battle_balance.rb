# frozen_string_literal: true

module Pokemons
  module Engine
    # The numbers a battle runs on. Trait-specific numbers live with their trait.
    BattleBalance = Data.define(:team_size, :tiredness_steps, :default_tiredness, :experience_steps,
                                :experience_cap, :type_chart) do
      # Tiredness the round winner takes, by how far its score beat the loser's.
      def tiredness_for(margin)
        tiredness_steps.find { |min_margin, _| margin >= min_margin }&.last || default_tiredness
      end

      # Experience a Pokémon gains from a round, by how close the opponent's experience is to its own.
      def experience_gain(own, opponent)
        experience_steps.find { |window, _| own - window < opponent }&.last || 0
      end
    end

    BattleBalance::V1 = BattleBalance.new(
      team_size: 6,
      tiredness_steps: [[201, 0.15], [101, 0.2]].freeze,
      default_tiredness: 0.25,
      experience_steps: [[10, 2], [15, 1]].freeze,
      experience_cap: 100,
      type_chart: TypeChart.default
    )
  end
end
