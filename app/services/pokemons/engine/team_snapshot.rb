# frozen_string_literal: true

module Pokemons
  module Engine
    # A trainer's Pokémon at the moment the battle starts. Order matters: it is the order luck is rolled in.
    TeamSnapshot = Data.define(:trainer_id, :combatants) do
      def initialize(trainer_id:, combatants:)
        super(trainer_id:, combatants: combatants.dup.freeze)
      end
    end
  end
end
