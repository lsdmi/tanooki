# frozen_string_literal: true

class PokemonService
  attr_reader :session

  def initialize(session:)
    @session = session
  end

  def call
    set_session_variables

    return nil if rand > session[:pokemon_catch_rate]

    caught_pokemon
  end

  private

  def caught_pokemon
    Pokemon.find_by(id: caught_pokemon_id)
  end

  def caught_pokemon_id
    pokemon_array = []

    Pokemon.includes(sprite_attachment: :blob).each do |pokemon|
      populate_pokemon_array(pokemon.rarity, pokemon_array, pokemon)
    end

    pokemon_array.sample
  end

  def populate_pokemon_array(rarity, pokemon_array, pokemon)
    case rarity
    when 1 then 10.times { pokemon_array << pokemon.id }
    when 2 then 5.times { pokemon_array << pokemon.id }
    when 3 then 3.times { pokemon_array << pokemon.id }
    when 4 then 2.times { pokemon_array << pokemon.id }
    when 5 then pokemon_array << pokemon.id
    end
  end

  def set_session_variables
    session[:pokemon_catch_rate] = session[:pokemon_catch_rate]&.present? ? (session[:pokemon_catch_rate] / 2) : 0.3
    session[:permitted_catch] = true
  end
end
