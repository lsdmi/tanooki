# frozen_string_literal: true

class PokemonCatchService
  attr_reader :pokemon_id, :user_id, :session

  def initialize(pokemon_id:, user_id:, session:)
    @pokemon_id = pokemon_id
    @user_id = user_id
    @session = session
  end

  def trap
    UserPokemon.create(pokemon_id:, user_id:)
    session[:pokemon_catch_permitted] = false
  end
end
