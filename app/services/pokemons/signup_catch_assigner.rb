# frozen_string_literal: true

module Pokemons
  # On user signup: grant a random starter or claim the guest wild-catch held in session.
  class SignupCatchAssigner
    def initialize(user, session)
      @user = user
      @session = session
    end

    def perform
      if @session[:pokemon_guest_caught].nil? || @session[:caught_pokemon_id].nil?
        CollectionUpdater.new(pokemon_id: nil, user_id: @user.id).grant
      else
        CollectionUpdater.new(pokemon_id: @session[:caught_pokemon_id], user_id: @user.id).trap
      end
      @user.inactive_message.presence
    end
  end
end
