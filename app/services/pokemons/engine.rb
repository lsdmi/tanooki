# frozen_string_literal: true

module Pokemons
  # Pure battle rules: two TeamSnapshots and an injected Random in, a Result out. No ActiveRecord, no rendering, no
  # global randomness, so a battle is reproducible from (VERSION, seed, snapshots).
  module Engine
    # The version new battles are fought with. Bump only with a rule change; old battles replay on the version they
    # were fought with.
    VERSION = 2
    VERSIONS = [1, 2].freeze

    def self.simulate(attacker:, defender:, seed:, version: VERSION)
      simulator(version).call(attacker:, defender:, rng: Random.new(seed))
    end

    # The rules class for +version+; its +call+ takes the teams and an rng.
    def self.simulator(version)
      case version
      when Simulator::VERSION then Simulator
      when HpSimulator::VERSION then HpSimulator
      else raise ArgumentError, "Unknown engine version #{version}"
      end
    end
  end
end
