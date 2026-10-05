# frozen_string_literal: true

module Pokemons
  # Pins one battle opponent per user, so the battle endpoint fights whoever the page showed, never an id from the form.
  class Matchmaker
    PIN_TTL = 24.hours
    REROLL_ATTEMPTS = 3

    def initialize(user, leaderboard: DexLeaderboard.new)
      @user = user
      @leaderboard = leaderboard
    end

    # The current pin, or nil. Never pins anyone, so a battle request cannot pick its own opponent.
    def pinned_opponent
      return unless profile.pinned_opponent_id && profile.pinned_until&.future?

      opponent = User.find_by(id: profile.pinned_opponent_id)
      opponent if opponent && opponent.id != user.id && @leaderboard.on_leaderboard?(opponent)
    end

    # The current pin, pinning a fresh opponent when it is missing, expired, or no longer valid.
    def opponent
      pinned_opponent || profile.with_lock { pinned_opponent || pin(@leaderboard.opponent_for(user)) }
    end

    def reroll_available?
      return false if BattleLeaderboardCooldown.call(user)

      profile.opponent_rerolled_at.nil? || profile.opponent_rerolled_at <= Balance::BATTLE_COOLDOWN.ago
    end

    # True when the reroll was spent; false when it was already used this window or the team is resting.
    def reroll!
      profile.with_lock do
        next false unless reroll_available?

        profile.opponent_rerolled_at = Time.current
        pin(fresh_opponent(excluding: profile.pinned_opponent_id))
        true
      end
    end

    def release!
      pin(nil)
    end

    private

    attr_reader :user

    def profile = user.trainer_profile

    def fresh_opponent(excluding:)
      candidate = nil
      REROLL_ATTEMPTS.times do
        candidate = @leaderboard.opponent_for(user)
        break if candidate.nil? || candidate.id != excluding
      end
      candidate
    end

    def pin(opponent)
      profile.update!(pinned_opponent_id: opponent&.id, pinned_until: opponent && PIN_TTL.from_now)
      opponent
    end
  end
end
