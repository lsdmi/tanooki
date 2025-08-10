# frozen_string_literal: true

class PokemonSignupHandler
  def initialize(user, session)
    @user = user
    @session = session
  end

  def call
    return unless pokemon_caught_before_signup?

    PokemonCatchService.new(pokemon_id: @session[:caught_pokemon_id], user_id: @user.id).trap
  end

  private

  def pokemon_caught_before_signup?
    @session[:pokemon_guest_caught].nil? || @session[:caught_pokemon_id].nil?
  end
end
