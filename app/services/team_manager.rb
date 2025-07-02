# frozen_string_literal: true

class TeamManager
  def initialize(team)
    @team = team
  end

  def find_active_pokemon
    @team.find { |pokemon| pokemon[:active] }
  end

  def deactivate_pokemon(pokemon_id)
    pokemon = find_pokemon_by_id(pokemon_id)
    pokemon[:active] = false if pokemon
  end

  def add_tiredness(pokemon_id, amount)
    pokemon = find_pokemon_by_id(pokemon_id)
    pokemon[:tiredness] += amount if pokemon
  end

  def reduce_tiredness(pokemon_id, amount)
    pokemon = find_pokemon_by_id(pokemon_id)
    pokemon[:tiredness] -= amount if pokemon
  end

  def has_active_pokemon?
    @team.any? { |pokemon| pokemon[:active] }
  end

  def active_pokemon_count
    @team.count { |pokemon| pokemon[:active] }
  end

  attr_reader :team

  private

  def find_pokemon_by_id(pokemon_id)
    @team.find { |pokemon| pokemon[:id] == pokemon_id }
  end
end
