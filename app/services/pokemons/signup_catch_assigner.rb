# frozen_string_literal: true

module Pokemons
  # On user signup: grant a random starter or claim the guest wild-catch held in session.
  class SignupCatchAssigner
    def initialize(user, session)
      @user = user
      @session = session
    end

    def perform
      unless AuthCatch.transfer_guest_catch!(user: @user, session: @session)
        CollectionUpdater.new(pokemon_id: nil, user_id: @user.id).grant
      end
      @user.inactive_message.presence
    end
  end
end
