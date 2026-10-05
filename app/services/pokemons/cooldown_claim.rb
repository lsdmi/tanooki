# frozen_string_literal: true

module Pokemons
  # Runs a cooldown-gated action at most once per window. The trainer profile row lock makes a second tab or device
  # wait, then read the fresh timestamp and be refused.
  class CooldownClaim
    CLOCKS = {
      catch: [:last_catch_at, Balance::CATCH_COOLDOWN],
      training: [:last_training_at, Balance::TRAINING_COOLDOWN]
    }.freeze

    def self.call(user, action, &)
      new(user, action).call(&)
    end

    def initialize(user, action)
      @profile = user.trainer_profile
      @column, @cooldown = CLOCKS.fetch(action)
    end

    # Returns the block's result, or nil while on cooldown. The clock starts only when the block returns something
    # truthy, so a failed catch (stale or foreign token) does not cost the user their cooldown.
    def call
      @profile.with_lock do
        next if @profile[@column]&.after?(@cooldown.ago)

        yield.tap { |result| @profile.update!(@column => Time.current) if result }
      end
    end
  end
end
