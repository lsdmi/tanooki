# frozen_string_literal: true

module Pokemons
  # Both trainers' fielded rosters: the attacker's attack team and the defender's defense team (ordered, ≤ TEAM_SIZE).
  # Engine snapshots for the simulation, the rows a PokemonBattle stores, and experience written back.
  class BattleTeams
    attr_reader :trainers

    def initialize(attacker, defender)
      @trainers = [attacker, defender]
      @rosters = {
        attacker: TeamRoster.new(attacker, :attack).records,
        defender: TeamRoster.new(defender, :defense).records
      }
      ids = @rosters.values.flat_map { |records| records.map(&:id) }.uniq
      @records = UserPokemon.where(id: ids).includes(pokemon: :pokemon_types).index_by(&:id)
    end

    def snapshot(side)
      Engine::TeamSnapshot.new(trainer_id: trainer(side).id, combatants: combatants(side).map(&:first))
    end

    def stored(side)
      combatants(side).map { |combatant, record| combatant.to_h.merge(pokemon_id: record.pokemon_id) }
    end

    def save_experience(experience)
      experience.each { |id, battle_experience| @records.fetch(id).update!(battle_experience:) }
    end

    private

    def trainer(side)
      side == :attacker ? trainers.first : trainers.last
    end

    def combatants(side)
      @combatants ||= {}
      @combatants[side] ||= @rosters.fetch(side).filter_map do |record|
        loaded = @records[record.id] || record
        [combatant(loaded), loaded]
      end
    end

    def combatant(record)
      species = record.pokemon
      Engine::Combatant.new(id: record.id, character: record.character,
                            battle_experience: record.battle_experience, types: species.types.map(&:key),
                            base_hp: species.base_hp, base_attack: species.base_attack)
    end
  end
end
