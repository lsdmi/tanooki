# frozen_string_literal: true

module Pokemons
  # Runs one trainer-vs-trainer battle: snapshots both teams, simulates it with +Engine::Simulator+, then saves the
  # experience and renders the log. Every database write happens after the simulation.
  class BattleRun
    attr_reader :attacker_id, :defender_id, :seed, :winner_id, :loser_id, :outcome_blocks

    def initialize(attacker_pokemons:, defender_pokemons:, attacker_id:, defender_id:, seed: Random.new_seed)
      @teams = { attacker: preload(attacker_pokemons), defender: preload(defender_pokemons) }
      @attacker_id = attacker_id
      @defender_id = defender_id
      @seed = seed
      @outcome_blocks = []
    end

    def append_log(message, type = :outcome)
      case type
      when :start then @start_message = message
      when :conclusion then @conclusion_message = message
      else @outcome_blocks << message
      end
    end

    def fight_details
      BattleDetailsPresenter.new(@start_message, @outcome_blocks, @conclusion_message).render
    end

    def start_battle
      result = Engine::Simulator.call(attacker: snapshot(:attacker, attacker_id),
                                      defender: snapshot(:defender, defender_id), rng: Random.new(seed))
      save_experience(result.experience)
      @winner_id, @loser_id = result.attacker_won? ? [attacker_id, defender_id] : [defender_id, attacker_id]
      render_log(result)
    end

    private

    def preload(pokemons)
      pokemons.includes(pokemon: [:pokemon_types, { sprite_attachment: :blob }]).order(:id).to_a
    end

    def records
      @records ||= @teams.values.flatten.index_by(&:id)
    end

    def snapshot(side, trainer_id)
      Engine::TeamSnapshot.new(trainer_id:, combatants: @teams[side].map do |record|
        Engine::Combatant.new(id: record.id, character: record.character,
                              power_level: record.pokemon.read_attribute(:power_level),
                              battle_experience: record.battle_experience, types: record.pokemon.types.map(&:name))
      end)
    end

    def save_experience(experience)
      experience.each { |id, battle_experience| records.fetch(id).update!(battle_experience:) }
    end

    def render_log(result)
      logger = Battle::LogRenderer.new(attacker_id, defender_id, self)
      append_log(logger.start, :start)
      rounds(result).each { |attacker, defender, outcome| logger.append_outcome(attacker, defender, outcome) }
      append_log(logger.conclusion(result.attacker_won? ? :victory : :defeat), :conclusion)
    end

    def rounds(result)
      result.events_of(:round_started).zip(result.events_of(:fainted)).map do |start, fainted|
        attacker, defender = start.data.values_at(:attacker, :defender).map { |id| records.fetch(id) }
        [attacker, defender, fainted.data[:side] == :defender ? :victory : :defeat]
      end
    end
  end
end
