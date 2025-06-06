# frozen_string_literal: true

class PokemonTeamBuilder
  def initialize(pokemon_list, team_limit)
    @pokemon_list = pokemon_list
    @team_limit = team_limit
  end

  def build_team
    @pokemon_list
      .map { |pokemon| build_member_data(pokemon) }
      .sort_by { |data| -data[:raw_total] }
      .first(@team_limit)
  end

  private

  def build_member_data(pokemon)
    power = calculate_power(pokemon)
    experience = calculate_experience(pokemon)
    luck = calculate_luck(pokemon)

    {
      active: true,
      all_types: pokemon.pokemon.types.pluck(:name),
      character: pokemon.character,
      experience: experience,
      id: pokemon.id,
      luck: luck,
      power: power,
      raw_total: (power + experience) * luck,
      tiredness: 1,
      type: 1
    }
  end

  def calculate_power(user_pokemon)
    multiplier = user_pokemon.character == 'independent' ? 120 : 100
    Pokemon::POWER_LEVELS[user_pokemon.pokemon_power_level] * multiplier
  end

  def calculate_experience(user_pokemon)
    bonus = user_pokemon.character == 'brave' ? 2 : 1
    user_pokemon.battle_experience * bonus
  end

  def calculate_luck(user_pokemon)
    range = user_pokemon.character == 'lucky' ? (1.0..1.2) : (0.9..1.1)
    rand(range)
  end
end
