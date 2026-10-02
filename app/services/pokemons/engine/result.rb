# frozen_string_literal: true

module Pokemons
  module Engine
    # +winner+ is :attacker or :defender; +experience+ maps each combatant id whose battle experience changed to its
    # new value.
    Result = Data.define(:engine_version, :winner, :events, :experience) do
      def initialize(engine_version:, winner:, events:, experience:)
        super(engine_version:, winner:, events: events.dup.freeze, experience: experience.dup.freeze)
      end

      def attacker_won?
        winner == :attacker
      end

      def events_of(type)
        events.select { |event| event.type == type }
      end
    end
  end
end
