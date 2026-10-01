# frozen_string_literal: true

module Pokemons
  # Runs a cooldown-gated action at most once per window. The user row lock makes a second tab or device wait, then
  # read the fresh timestamp and be refused.
  class CooldownClaim
    CLOCKS = {
      catch: [:pokemon_last_catch, Balance::CATCH_COOLDOWN],
      training: [:pokemon_last_training, Balance::TRAINING_COOLDOWN]
    }.freeze

    def self.call(user, action, &)
      new(user, action).call(&)
    end

    def initialize(user, action)
      @user = user
      @column, @cooldown = CLOCKS.fetch(action)
    end

    # Returns the block's result, or nil while on cooldown. The clock starts only when the block returns something
    # truthy, so a failed catch (stale or foreign token) does not cost the user their cooldown.
    def call
      @user.with_lock do
        next if @user[@column] > @cooldown.ago

        yield.tap { |result| stamp! if result }
      end
    end

    private

    # Skips validations: only the game clock changes, and legacy rows may fail newer User rules (e.g. name length).
    def stamp!
      @user.assign_attributes(@column => Time.current)
      @user.save!(validate: false)
    end
  end
end
