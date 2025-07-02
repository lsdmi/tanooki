# frozen_string_literal: true

class PokemonBattleService
  attr_reader :attacker_pokemons, :defender_pokemons, :attacker_id, :defender_id, :battle_log, :winner_id, :loser_id,
              :outcome_blocks

  def initialize(attacker_pokemons:, defender_pokemons:, attacker_id:, defender_id:)
    @attacker_pokemons = attacker_pokemons
    @defender_pokemons = defender_pokemons
    @attacker_id = attacker_id
    @defender_id = defender_id
    @battle_log = ''
    @winner_id = nil
    @loser_id = nil
    @outcome_blocks = []
    @start_message = nil
    @conclusion_message = nil
  end

  def append_log(message, type = :outcome)
    case type
    when :start
      @start_message = message
    when :conclusion
      @conclusion_message = message
    else
      @outcome_blocks << message
    end
  end

  def assign_winner(id)
    @winner_id = id
  end

  def assign_loser(id)
    @loser_id = id
  end

  def fight_details
    BattleDetailsPresenter.new(@start_message, @outcome_blocks, @conclusion_message).render
  end

  def start_battle
    logger = BattleLogger.new(attacker_id, defender_id, self)
    append_log(logger.start, :start)

    attacker_team = initialize_team(@attacker_pokemons)
    defender_team = initialize_team(@defender_pokemons)

    battle_engine = BattleEngine.new(attacker_team, defender_team, logger)

    battle_engine.execute_round while battle_engine.battle_continues?

    conclude_battle(battle_engine, logger)
  end

  private

  def conclude_battle(battle_engine, logger)
    result = battle_engine.attacker_won? ? :victory : :defeat
    append_log(logger.conclusion(result), :conclusion)
    assign_winner_and_loser(result)
  end

  def assign_winner_and_loser(result)
    if result == :victory
      assign_winner(attacker_id)
      assign_loser(defender_id)
    else
      assign_winner(defender_id)
      assign_loser(attacker_id)
    end
  end

  def pokemon_limit
    [UserPokemon::DEFAULT_TEAM_SIZE, @attacker_pokemons.size, @defender_pokemons.size].min
  end

  def initialize_team(pokemon_list)
    PokemonTeamBuilder.new(pokemon_list, pokemon_limit).build_team
  end
end
