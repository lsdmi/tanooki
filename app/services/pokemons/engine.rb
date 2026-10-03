# frozen_string_literal: true

module Pokemons
  # Pure battle rules: two TeamSnapshots and an injected Random in, a Result out. No ActiveRecord, no rendering, no
  # global randomness, so a battle is reproducible from (VERSION, seed, snapshots).
  module Engine
    # Bump only with a rule change; old battles replay on the version they were fought with.
    VERSION = 1

    def self.simulate(attacker:, defender:, seed:, version: VERSION)
      raise ArgumentError, "Unknown engine version #{version}" unless version == 1

      Simulator.call(attacker:, defender:, rng: Random.new(seed), balance: BattleBalance::V1)
    end
  end
end
