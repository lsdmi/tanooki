# frozen_string_literal: true

class PokemonService
  def initialize(user:, session:)
    @user = user
    @session = session
  end

  def call
    return nil if @user&.pokemon_last_catch&.> 4.hours.ago

    pokemon = select_random_pokemon
    return nil unless pokemon

    @session[:pokemon] = pokemon
    pokemon
  end

  private

  def select_random_pokemon
    return nil if @user.nil?

    last_seen = @user&.pokemon_last_catch || @session[:pokemon_catch_last_seen]
    return nil if last_seen && last_seen > 4.hours.ago

    available_pokemon = Pokemon.where.not(id: @user.pokemons.pluck(:id))
    return nil if available_pokemon.empty?

    pokemon = available_pokemon.sample
    caught_pokemon_id = pokemon.id

    @session[:caught_pokemon_id] = caught_pokemon_id
    Pokemon.find_by(id: @session[:caught_pokemon_id])
  end

  def pokemon_catch_permitted?
    return true if @user.nil?

    last_catch = @user.pokemon_last_catch
    return true if last_catch.nil?

    last_catch < 4.hours.ago
  end

  def pokemon_catch_last_seen
    return Time.now if @user.nil?

    @session[:pokemon_catch_last_seen] ||= Time.now
    @session[:pokemon_guest_caught] = nil
    @session[:pokemon_catch_last_seen]
  end

  def pokemon_catch_last_seen=(time)
    @session[:pokemon_catch_last_seen] = time
  end
end
