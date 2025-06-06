# frozen_string_literal: true

class PokemonBattleService
  attr_reader :attacker_pokemons, :defender_pokemons, :attacker_id, :defender_id, :battle_log, :winner_id, :loser_id

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
    grid_content = @outcome_blocks.dup
    if grid_content.size.odd?
      grid_content << @conclusion_message
      conclusion_html = ''
    else
      conclusion_html = @conclusion_message
    end

    <<~HTML.html_safe
      #{@start_message}
      <div class="grid grid-cols-1 sm:grid-cols-2 gap-3 mb-2">
        #{grid_content.join}
      </div>
      #{conclusion_html}
    HTML
  end

  def start_battle
    logger = BattleLogger.new(attacker_id, defender_id)
    append_log(logger.start, :start)

    attacker_team = initialize_team(@attacker_pokemons)
    defender_team = initialize_team(@defender_pokemons)

    while active_pokemon?(attacker_team) && active_pokemon?(defender_team)
      attacker_stats = attacker_team.find { |pokemon| pokemon[:active] }.dup
      defender_stats = defender_team.find { |pokemon| pokemon[:active] }.dup

      attacker = UserPokemon.find(attacker_stats[:id])
      defender = UserPokemon.find(defender_stats[:id])

      if [attacker.character, defender.character].include?('friendly')
        CharacterHandler.handle_friendly_character(attacker_stats, defender_stats)
      end

      CharacterHandler.handle_ambitious_character(defender_stats, defender) if attacker.character == 'ambitious'
      CharacterHandler.handle_ambitious_character(attacker_stats, attacker) if defender.character == 'ambitious'

      CharacterHandler.handle_prideful_character(defender_stats) if attacker.character == 'prideful'
      CharacterHandler.handle_prideful_character(attacker_stats) if defender.character == 'prideful'

      calculate_type_effectiveness(attacker_stats, attacker.pokemon, defender.pokemon)
      calculate_type_effectiveness(defender_stats, defender.pokemon, attacker.pokemon)

      CharacterHandler.handle_patient_character(attacker_stats, defender_stats) if attacker.character == 'patient'
      CharacterHandler.handle_patient_character(defender_stats, attacker_stats) if defender.character == 'patient'

      CharacterHandler.handle_decisive_character(attacker_stats, defender_stats) if attacker.character == 'decisive'
      CharacterHandler.handle_decisive_character(defender_stats, attacker_stats) if defender.character == 'decisive'

      attacker_experience = attacker.battle_experience
      defender_experience = defender.battle_experience

      if calculate_battle_result(attacker_stats) > calculate_battle_result(defender_stats)
        handle_victory(attacker, defender, attacker_team, defender_team, attacker_stats, defender_stats, logger)
      else
        handle_defeat(attacker, defender, attacker_team, defender_team, attacker_stats, defender_stats, logger)
      end

      update_experience(attacker, defender, attacker_experience, defender_experience)
    end

    conclude_battle(attacker_team, logger)
  end

  private

  def handle_victory(attacker, defender, attacker_team, defender_team, attacker_stats, defender_stats, logger)
    append_log(logger.outcome(attacker, defender, :victory, @outcome_blocks.size + 1))
    defender_team.find { |pokemon| pokemon[:id] == defender_stats[:id] }[:active] = false
    tiredness_to_add = tiredness_stat(attacker_stats, defender_stats)
    attacker_team.find { |pokemon| pokemon[:id] == attacker_stats[:id] }[:tiredness] += tiredness_to_add
    CharacterHandler.handle_hardy_character(attacker_team, attacker_stats) if attacker.character == 'hardy'
    CharacterHandler.handle_agile_character(attacker_team, attacker_stats) if defender.character == 'agile'
  end

  def handle_defeat(attacker, defender, attacker_team, defender_team, attacker_stats, defender_stats, logger)
    append_log(logger.outcome(attacker, defender, :defeat, @outcome_blocks.size + 1))
    attacker_team.find { |pokemon| pokemon[:id] == attacker_stats[:id] }[:active] = false
    tiredness_to_add = tiredness_stat(defender_stats, attacker_stats)
    defender_team.find { |pokemon| pokemon[:id] == defender_stats[:id] }[:tiredness] += tiredness_to_add
    CharacterHandler.handle_hardy_character(defender_team, defender_stats) if defender.character == 'hardy'
    CharacterHandler.handle_agile_character(defender_team, defender_stats) if attacker.character == 'agile'
  end

  def update_experience(attacker, defender, attacker_experience, defender_experience)
    attacker_got_experience = calculate_experience_gain(attacker_experience, defender_experience)
    defender_got_experience = calculate_experience_gain(defender_experience, attacker_experience)

    attacker.update(battle_experience: exp_gain(attacker.character, attacker_experience, attacker_got_experience))
    defender.update(battle_experience: exp_gain(defender.character, defender_experience, defender_got_experience))

    CharacterHandler.handle_persistent_character(attacker, attacker_experience) if attacker.character == 'persistent'
    CharacterHandler.handle_persistent_character(defender, defender_experience) if defender.character == 'persistent'
  end

  def conclude_battle(attacker_team, logger)
    result = active_pokemon?(attacker_team) ? :victory : :defeat
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

  def active_pokemon?(team)
    team.any? { |pokemon| pokemon[:active] }
  end

  def calculate_battle_result(stats)
    stats[:raw_total] * stats[:type] / stats[:tiredness]
  end

  def calculate_experience_gain(attacker_experience, defender_experience)
    if (attacker_experience - 10) < defender_experience
      2
    elsif (attacker_experience - 15) < defender_experience
      1
    else
      0
    end
  end

  def calculate_type_effectiveness(stats, own_pokemon, opponent_pokemon)
    effectiveness = 1.0

    own_pokemon.types.each do |attacker_type|
      opponent_pokemon.types.each do |defender_type|
        effectiveness *= TypeAdvantage.effectiveness(attacker_type.name, defender_type.name)
      end
    end

    stats[:type] = effectiveness
  end

  def exp_gain(character, experience, got_experience)
    if got_experience.nonzero? && experience < 115 && character == 'confident'
      got_experience *= 2
      experience += got_experience
    elsif got_experience.nonzero? && experience < 100
      experience += got_experience
    end

    experience
  end

  def pokemon_limit
    [UserPokemon::DEFAULT_TEAM_SIZE, @attacker_pokemons.size, @defender_pokemons.size].min
  end

  def tiredness_stat(attacker, defender)
    case (calculate_battle_result(attacker) - calculate_battle_result(defender))
    when 201..Float::INFINITY
      0.15
    when 101..200
      0.2
    else
      0.25
    end
  end

  def initialize_team(pokemon_list)
    PokemonTeamBuilder.new(pokemon_list, pokemon_limit).build_team
  end
end
