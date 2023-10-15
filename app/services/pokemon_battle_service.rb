# frozen_string_literal: true

class PokemonBattleService
  include Rails.application.routes.url_helpers

  attr_reader :attacker_pokemons, :defender_pokemons, :attacker_id, :defender_id, :battle_log, :winner_id, :loser_id

  def initialize(attacker_pokemons:, defender_pokemons:, attacker_id:, defender_id:)
    @attacker_pokemons = attacker_pokemons
    @defender_pokemons = defender_pokemons
    @attacker_id = attacker_id
    @defender_id = defender_id
    @battle_log = ''
    @winner_id = nil
    @loser_id = nil

    default_url_options[:host] = Rails.env.production? ? 'baka.in.ua' : 'localhost:3000'
  end

  def append_log(message)
    @battle_log += "#{message}\n"
  end

  def assign_winner(id)
    @winner_id = id
  end

  def assign_loser(id)
    @loser_id = id
  end

  def fight_details
    @battle_log
  end

  def start_battle
    append_log(
      ActionController::Base.helpers.sanitize(
        "<div class='mb-4 font-light inline-block'>Вітаємо вас на Арені, шанові глядачі! Сьогодні " \
        " ми станемо свідками неймовірного " \
        "протистояння між <span class='font-bold'>#{attacker_username}</span> та " \
        "<span class='font-bold'>#{defender_username}</span>!</div>" \
      )
    )

    attacker_team = initialize_team(@attacker_pokemons)
    defender_team = initialize_team(@defender_pokemons)

    while active_pokemon?(attacker_team) && active_pokemon?(defender_team)
      attacker_stats = attacker_team.find { |pokemon| pokemon[:active] }.dup
      defender_stats = defender_team.find { |pokemon| pokemon[:active] }.dup

      attacker = UserPokemon.find(attacker_stats[:id])
      defender = UserPokemon.find(defender_stats[:id])

      if [attacker.character, defender.character].include?('friendly')
        handle_friendly_character(attacker_stats, defender_stats)
      end
      handle_ambitious_character(defender_stats, defender) if attacker.character == 'ambitious'
      handle_ambitious_character(attacker_stats, attacker) if defender.character == 'ambitious'
      handle_prideful_character(defender_stats) if attacker.character == 'prideful'
      handle_prideful_character(attacker_stats) if defender.character == 'prideful'
      calculate_type_effectiveness(attacker_stats, attacker.pokemon, defender.pokemon)
      calculate_type_effectiveness(defender_stats, defender.pokemon, attacker.pokemon)
      handle_patient_character(attacker_stats, defender_stats) if attacker.character == 'patient'
      handle_patient_character(defender_stats, attacker_stats) if defender.character == 'patient'
      handle_decisive_character(attacker_stats, defender_stats) if attacker.character == 'decisive'
      handle_decisive_character(defender_stats, attacker_stats) if defender.character == 'decisive'

      attacker_experience = attacker.battle_experience
      defender_experience = defender.battle_experience

      if calculate_battle_result(attacker_stats) > calculate_battle_result(defender_stats)
        append_log(
          ActionController::Base.helpers.sanitize(
            "<div class='flex justify-center text-center'>
              <div class='mb-4 grid grid-cols-3 gap-2'>
                <div class='flex flex-col items-center justify-center text-center'>
                  <div class='flex items-center justify-center h-8 w-14 border-2 shadow-md rounded-full mb-1'>
                    <img src='#{url_for(attacker.pokemon.sprite)}'
                          alt='#{attacker.pokemon.sprite.blob.filename}'
                          class='w-auto cursor-pointer rounded-lg transform transition duration-500 hover:scale-110'>
                  </div>
                </div>

                <div class='flex flex-col items-center justify-center text-center'>
                  <span class='font-light text-gray-600'>перемагає</span>
                </div>

                <div class='flex flex-col items-center justify-center text-center'>
                  <div class='flex items-center justify-center h-8 w-14 border-2 shadow-md rounded-full mb-1'>
                  <img src='#{url_for(defender.pokemon.sprite)}'
                        alt='#{defender.pokemon.sprite.blob.filename}'
                        class='w-auto cursor-pointer rounded-lg transform transition duration-500 hover:scale-110'>
                  </div>
                </div>
              </div>
            </div"
          )
        )

        defender_team.find { |pokemon| pokemon[:id] == defender_stats[:id] }[:active] = false

        tiredness_to_add = tiredness_stat(attacker_stats, defender_stats)
        attacker_team.find { |pokemon| pokemon[:id] == attacker_stats[:id] }[:tiredness] += tiredness_to_add

        handle_hardy_character(attacker_team, attacker_stats) if attacker.character == 'hardy'
        handle_agile_character(attacker_team, attacker_stats) if defender.character == 'agile'

        attacker_got_experience = calculate_experience_gain(attacker_experience, defender_experience)
        defender_got_experience = (defender_experience - 15) < attacker_experience ? 1 : 0
      else
        append_log(
          ActionController::Base.helpers.sanitize(
            "<div class='flex justify-center text-center'>
              <div class='mb-4 grid grid-cols-3 gap-2'>
                <div class='flex flex-col items-center justify-center text-center'>
                  <div class='flex items-center justify-center h-8 w-14 border-2 shadow-md rounded-full mb-1'>
                    <img src='#{url_for(attacker.pokemon.sprite)}'
                          alt='#{attacker.pokemon.sprite.blob.filename}'
                          class='w-auto cursor-pointer rounded-lg transform transition duration-500 hover:scale-110'>
                  </div>
                </div>

                <div class='flex flex-col items-center justify-center text-center'>
                  <span class='font-light text-gray-600'>програє</span>
                </div>

                <div class='flex flex-col items-center justify-center text-center'>
                  <div class='flex items-center justify-center h-8 w-14 border-2 shadow-md rounded-full mb-1'>
                  <img src='#{url_for(defender.pokemon.sprite)}'
                        alt='#{defender.pokemon.sprite.blob.filename}'
                        class='w-auto cursor-pointer rounded-lg transform transition duration-500 hover:scale-110'>
                  </div>
                </div>
              </div>
            </div"
          )
        )

        attacker_team.find { |pokemon| pokemon[:id] == attacker_stats[:id] }[:active] = false

        tiredness_to_add = tiredness_stat(defender_stats, attacker_stats)
        defender_team.find { |pokemon| pokemon[:id] == defender_stats[:id] }[:tiredness] += tiredness_to_add

        handle_hardy_character(defender_team, defender_stats) if defender.character == 'hardy'
        handle_agile_character(defender_team, defender_stats) if attacker.character == 'agile'

        defender_got_experience = calculate_experience_gain(defender_experience, attacker_experience)
        attacker_got_experience = (attacker_experience - 15) < defender_experience ? 1 : 0
      end

      attacker_experience = handle_experience_gain(attacker.character, attacker_experience, attacker_got_experience)
      attacker.update(battle_experience: attacker_experience)

      defender_experience = handle_experience_gain(defender.character, defender_experience, defender_got_experience)
      defender.update(battle_experience: defender_experience)

      handle_persistent_character(attacker, attacker_experience) if attacker.character == 'persistent'
      handle_persistent_character(defender, defender_experience) if defender.character == 'persistent'
    end

    if active_pokemon?(attacker_team)
      append_log(
        ActionController::Base.helpers.sanitize(
          "\n
          <div class='mt-4 font-light inline-block'>
            І-і... все! Останній покемон
            <span class='font-bold'>#{defender_username}</span> падає без сил, тож
            <span class='font-bold'>#{attacker_username}</span> святкує перемогу в цьому бою!
          </div>"
        )
      )
    else
      append_log(
        ActionController::Base.helpers.sanitize(
          "\n
          <div class='mt-4 font-light inline-block'>
            І-і... все! Останній покемон
            <span class='font-bold'>#{attacker_username}</span> падає без сил, тож
            <span class='font-bold'>#{defender_username}</span> святкує перемогу в цьому бою!
          </div>"
        )
      )
    end

    if active_pokemon?(attacker_team)
      assign_winner(attacker_id)
      assign_loser(defender_id)
    else
      assign_winner(defender_id)
      assign_loser(attacker_id)
    end
  end

  private

  def attacker_username
    @attacker_username ||= User.find(attacker_id).name
  end

  def defender_username
    @defender_username ||= User.find(defender_id).name
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

  def handle_agile_character(team, stats)
    selected = team.find { |pokemon| pokemon[:id] == stats[:id] }
    selected[:tiredness] += 0.1
  end

  def handle_ambitious_character(stats, opponent)
    stats[:luck] = opponent.character == 'lucky' ? 1.0 : 0.9
    stats[:raw_total] = raw_strength_formula(stats[:power], stats[:luck], stats[:experience])
  end

  def handle_decisive_character(attacker_stats, defender_stats)
    attacker_stats[:type] += 0.1 if attacker_stats[:type] > defender_stats[:type]
  end

  def handle_experience_gain(character, experience, got_experience)
    if got_experience.nonzero? && experience < 115 && character == 'confident'
      got_experience *= 2
      experience += got_experience
    elsif got_experience.nonzero? && experience < 100
      experience += got_experience
    end

    experience
  end

  def handle_friendly_character(attacker, defender)
    [attacker, defender].each do |character_stats|
      character_stats[:experience] = 1
      character_stats[:raw_total] = raw_strength_formula(character_stats[:power], character_stats[:luck])
    end
  end

  def handle_hardy_character(team, stats)
    selected = team.find { |pokemon| pokemon[:id] == stats[:id] }
    selected[:tiredness] -= 0.1
  end

  def handle_patient_character(attacker_stats, defender_stats)
    defender_stats[:type] = attacker_stats[:type] if attacker_stats[:type] < defender_stats[:type]
  end

  def handle_persistent_character(character, experience)
    character.update(battle_experience: character.battle_experience + 1) if experience < 115
  end

  def handle_prideful_character(stats)
    stats[:power] = stats[:power] / 1.2
    stats[:raw_total] = raw_strength_formula(stats[:power], stats[:luck], stats[:experience])
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
    team_data = pokemon_list.map do |pokemon|
      power = calculate_power(pokemon)
      luck = calculate_luck(pokemon)
      experience = calculate_experience(pokemon)

      {
        active: true,
        all_types: pokemon.pokemon.types.pluck(:name),
        character: pokemon.character,
        experience:,
        id: pokemon.id,
        luck:,
        power:,
        raw_total: raw_strength_formula(power, luck, experience),
        tiredness: 1,
        type: 1
      }
    end

    sorted_team = team_data.sort_by { |data| -data[:raw_total] }
    sorted_team.first(pokemon_limit)
  end

  def raw_strength_formula(power, luck, experience = 0)
    (power + experience) * luck
  end

  def calculate_power(user_pokemon)
    multiplier = user_pokemon.character == 'independent' ? 120 : 100
    user_pokemon.pokemon.power_level * multiplier
  end

  def calculate_experience(user_pokemon)
    multiplier = user_pokemon.character == 'brave' ? 2 : 1
    user_pokemon.battle_experience * multiplier
  end

  def calculate_luck(user_pokemon)
    luck_range = user_pokemon.character == 'lucky' ? (1.0..1.2) : (0.9..1.1)
    rand(luck_range)
  end
end
