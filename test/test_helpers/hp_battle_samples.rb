# frozen_string_literal: true

# Random version 2 battles for property tests. The seeds are fixed, so a failure always reproduces.
module HpBattleSamples
  SEEDS = (1..200)
  DEFENDER_IDS = 1001
  CHARACTERS = [nil, *UserPokemon.characters.keys].freeze

  private

  # Yields the result, both teams and the seed.
  def each_battle
    SEEDS.each do |seed|
      random = Random.new(seed)
      attacker = random_team(random, 1)
      defender = random_team(random, DEFENDER_IDS)
      yield Pokemons::Engine::HpSimulator.call(attacker:, defender:, rng: Random.new(seed)), attacker, defender, seed
    end
  end

  # Yields each round's round_started event, its hits, and all its events.
  def each_round
    each_battle do |result|
      result.events.slice_before { |event| event.type == :round_started }.each do |start, *rest|
        yield start, rest.select { |event| event.type == :hit }, [start, *rest]
      end
    end
  end

  def combatants_by_id(*teams)
    teams.flat_map(&:combatants).index_by(&:id)
  end

  def random_team(random, first_id)
    combatants = Array.new(random.rand(1..8)) { |index| random_combatant(random, first_id + index) }
    Pokemons::Engine::TeamSnapshot.new(trainer_id: first_id, combatants:)
  end

  def random_combatant(random, id)
    stats = Pokemons::BaseStats.for(Pokemons::BaseStats.table.keys.sample(random:))
    types = Pokemons::Engine::TypeChart.default.types.sample(random.rand(1..2), random:)
    Pokemons::Engine::Combatant.new(id:, character: CHARACTERS.sample(random:), power_level: 1,
                                    battle_experience: random.rand(0..115), types:,
                                    base_hp: stats[:hp], base_attack: stats[:attack])
  end
end
