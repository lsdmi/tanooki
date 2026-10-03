# frozen_string_literal: true

module Pokemons
  # Both trainers' Pokémon from one query: engine snapshots for the simulation, the rows a PokemonBattle stores (each
  # combatant plus its species, for rendering), and the experience the battle earned written back.
  class BattleTeams
    attr_reader :trainers

    def initialize(attacker, defender)
      @trainers = [attacker, defender]
      @records = UserPokemon.where(user_id: [attacker.id, defender.id])
                            .includes(pokemon: :pokemon_types).order(:id).to_a
    end

    def snapshot(side)
      Engine::TeamSnapshot.new(trainer_id: trainer(side).id, combatants: combatants(side).map(&:first))
    end

    def stored(side)
      combatants(side).map { |combatant, record| combatant.to_h.merge(pokemon_id: record.pokemon_id) }
    end

    def save_experience(experience)
      by_id = @records.index_by(&:id)
      experience.each { |id, battle_experience| by_id.fetch(id).update!(battle_experience:) }
    end

    private

    def trainer(side)
      side == :attacker ? trainers.first : trainers.last
    end

    def combatants(side)
      @combatants ||= {}
      @combatants[side] ||= @records.select { |record| record.user_id == trainer(side).id }.map do |record|
        [Engine::Combatant.new(id: record.id, character: record.character,
                               power_level: record.pokemon.read_attribute(:power_level),
                               battle_experience: record.battle_experience, types: record.pokemon.types.map(&:name)),
         record]
      end
    end
  end
end
