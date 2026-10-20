# frozen_string_literal: true

module Pokemons
  # Trains one of the user's Pokémon, once per training cooldown.
  class Training
    def initialize(user, user_pokemon_id)
      @user = user
      @user_pokemon_id = user_pokemon_id
    end

    # Returns the notice text, or nil while on cooldown.
    def call
      notice = CooldownClaim.call(@user, :training) { train_with_egg! }
      DailyQuests::Progress.call(@user, event: :training) if notice
      notice
    end

    private

    def train_with_egg!
      record = @user.user_pokemons.find(@user_pokemon_id)
      profile = @user.trainer_profile
      multiplier = profile.item_effect('lucky_egg') ? 2 : 1
      result = record.train!(experience_multiplier: multiplier)
      profile.write_item_effect!('lucky_egg', nil) if multiplier > 1
      result[:alert]
    end
  end
end
