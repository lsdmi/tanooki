# frozen_string_literal: true

# Assigns a starter or guest-caught Pokemon on user signup.
class PokemonSignupHandler
  def initialize(user, session)
    @user = user
    @session = session
  end

  def perform
    if @session[:pokemon_guest_caught].nil? || @session[:caught_pokemon_id].nil?
      PokemonCatchService.new(pokemon_id: nil, user_id: @user.id).grant
    else
      PokemonCatchService.new(pokemon_id: @session[:caught_pokemon_id], user_id: @user.id).trap
    end
    @user.inactive_message.presence
  end
end
