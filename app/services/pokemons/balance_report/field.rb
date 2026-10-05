# frozen_string_literal: true

module Pokemons
  class BalanceReport
    # How often each species beats the rest one on one in today's battles, without traits and at experience 0, sides
    # alternating: the might the card shows (StatTiers, config/pokemon_might.yml via pokemons:might). Types count,
    # averaged over the field.
    class Field
      CHECK_REPEATS = 6
      CHECK_SEED = 2026

      # Mean distance between the win rates the card reads (config/pokemon_might.yml) and the ones today's battles
      # give the report's species; nil when the report is for a version new battles no longer run on.
      def self.drift(report)
        return unless report.version == Engine::VERSION

        new(species: report.species, repeats: CHECK_REPEATS, seed: CHECK_SEED).drift
      end

      def initialize(species:, repeats:, seed:)
        @simulator = Engine.simulator(Engine::VERSION)
        @species = species
        @repeats = repeats
        @seed = seed
      end

      # Win rate by dex number.
      def rates
        @rates ||= begin
          rng = Random.new(@seed)
          @species.to_h { |own| [own.dex_id, win_rate(own, rng)] }
        end
      end

      def drift
        @species.sum { |species| (rates.fetch(species.dex_id) - StatTiers.win_rate(species)).abs } / @species.size
      end

      private

      def win_rate(own, rng)
        games = (@species - [own]).flat_map do |other|
          Array.new(@repeats) { |i| wins?(own, other, rng, attacking: i.even?) }
        end
        games.count(true).fdiv(games.size)
      end

      def wins?(own, other, rng, attacking:)
        mine = snapshot(own, 1)
        theirs = snapshot(other, 2)
        attacking ? simulate(mine, theirs, rng).attacker_won? : !simulate(theirs, mine, rng).attacker_won?
      end

      def snapshot(species, id)
        combatant = Engine::Combatant.new(id:, character: nil, battle_experience: 0, types: species.types,
                                          base_hp: species.base_hp, base_attack: species.base_attack)
        Engine::TeamSnapshot.new(trainer_id: id, combatants: [combatant])
      end

      def simulate(attacker, defender, rng)
        @simulator.call(attacker:, defender:, rng:)
      end
    end
  end
end
