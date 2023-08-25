# frozen_string_literal: true

class PokemonService
  attr_reader :guest, :session

  def initialize(guest:, session:)
    @guest = guest
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
    elsif last_seen > 24.hours.ago then 0.01
    else
      0.001
    end
  end

  def caught_pokemon
    session[:caught_pokemon_id] = caught_pokemon_id if guest
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
    when 1 then 27.times { pokemon_array << pokemon.id }
    when 2 then 9.times { pokemon_array << pokemon.id }
    when 3 then 3.times { pokemon_array << pokemon.id }
    when 4 then pokemon_array << pokemon.id
    end
  end

  def precatch_session
    session[:pokemon_catch_last_seen] ||= Time.now

    session[:pokemon_catch_rate] = catch_rate
    session[:pokemon_catch_permitted] = false
    session[:pokemon_guest_caught] = nil
  end

  def postcatch_session
    session[:pokemon_catch_last_seen] = Time.now
    session[:pokemon_catch_permitted] = true
  end
end
