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
    {
      active: true, all_types: all_types(pokemon), character: character(pokemon),
      experience: experience(pokemon), id: pokemon.id, luck: luck(pokemon),
      power: power(pokemon), raw_total: raw_total(pokemon),
      tiredness: tiredness, type: type
    }
  end

  def all_types(pokemon)
    pokemon.pokemon.types.pluck(:name)
  end

  def character(pokemon)
    pokemon.character
  end

  def experience(pokemon)
    bonus = character(pokemon) == 'brave' ? 2 : 1
    pokemon.battle_experience * bonus
  end

  def luck(pokemon)
    range = character(pokemon) == 'lucky' ? (1.0..1.2) : (0.9..1.1)
    rand(range)
  end

  def power(pokemon)
    multiplier = character(pokemon) == 'independent' ? 120 : 100
    Pokemon::POWER_LEVELS[pokemon.pokemon_power_level] * multiplier
  end

  def raw_total(pokemon)
    (power(pokemon) + experience(pokemon)) * luck(pokemon)
  end

  def tiredness
    1
  end

  def type
    1
  end
end
