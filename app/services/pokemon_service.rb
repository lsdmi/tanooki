# frozen_string_literal: true

class PokemonService
  attr_reader :session

  def initialize(session:)
    @session = session
  end

  def call
    precatch_session

    return nil if rand > session[:pokemon_catch_rate]

    postcatch_session
    caught_pokemon
  end

  private

  def catch_rate
    last_seen = session[:pokemon_catch_last_seen]

    if last_seen < 365.days.ago then 1
    elsif last_seen > 24.hours.ago then 0.3
    else
      0.03
    end
  end

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

  def initialize_catch_info
    session[:pokemon_catch_rate] ||= 0.03
    session[:pokemon_catch_last_seen] ||= 23.hours.ago
    session[:pokemon_catch_permitted] ||= false
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

  def precatch_session
    initialize_catch_info

    session[:pokemon_catch_rate] = catch_rate
    session[:pokemon_catch_permitted] = false
  end

  def postcatch_session
    session[:pokemon_catch_last_seen] = Time.now
    session[:pokemon_catch_permitted] = true
  end
end
