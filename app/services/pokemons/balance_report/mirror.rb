# frozen_string_literal: true

module Pokemons
  class BalanceReport
    # Whether a battle, fought again with the sides swapped and the same seed, is its mirror image event for event.
    module Mirror
      KEYS = { attacker: :defender, defender: :attacker, attacker_score: :defender_score,
               defender_score: :attacker_score }.freeze

      def self.mirrored?(battle, simulator)
        swapped = simulator.call(attacker: battle.defender, defender: battle.attacker, rng: Random.new(battle.seed))
        swapped.events == battle.result.events.map { |event| event.with(data: flip(event.data)) } &&
          swapped.experience == battle.result.experience
      end

      def self.flip(data)
        data.to_h { |key, value| [KEYS.fetch(key, key), key == :side ? KEYS.fetch(value) : value] }
      end
    end
  end
end
