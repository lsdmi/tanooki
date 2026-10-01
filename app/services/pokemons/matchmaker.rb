# frozen_string_literal: true

module Pokemons
  # Pins one battle opponent per user, so the battle endpoint fights whoever the page showed, never an id from the form.
  class Matchmaker
    PIN_TTL = 24.hours
    REROLL_COOLDOWN = 4.hours
    REROLL_ATTEMPTS = 3

    def initialize(user, leaderboard: DexLeaderboard.new)
      @user = user
      @leaderboard = leaderboard
    end

    # The current pin, or nil. Never pins anyone, so a battle request cannot pick its own opponent.
    def pinned_opponent
      return unless user.pinned_opponent_id && user.pinned_until&.future?

      opponent = User.find_by(id: user.pinned_opponent_id)
      opponent if opponent && opponent.id != user.id && @leaderboard.on_leaderboard?(opponent)
    end

    # The current pin, pinning a fresh opponent when it is missing, expired, or no longer valid.
    def opponent
      pinned_opponent || user.with_lock { pinned_opponent || pin(@leaderboard.opponent_for(user)) }
    end

    def reroll_available?
      return false if BattleLeaderboardCooldown.call(user)

      user.opponent_rerolled_at.nil? || user.opponent_rerolled_at <= REROLL_COOLDOWN.ago
    end

    # True when the reroll was spent; false when it was already used this window or the team is resting.
    def reroll!
      user.with_lock do
        next false unless reroll_available?

        user.opponent_rerolled_at = Time.current
        pin(fresh_opponent(excluding: user.pinned_opponent_id))
        true
      end
    end

    def release!
      pin(nil)
    end

    private

    attr_reader :user

    def fresh_opponent(excluding:)
      candidate = nil
      REROLL_ATTEMPTS.times do
        candidate = @leaderboard.opponent_for(user)
        break if candidate.nil? || candidate.id != excluding
      end
      candidate
    end

    # Skips validations: only game columns change, and legacy rows may fail newer User rules (e.g. name length).
    def pin(opponent)
      user.assign_attributes(pinned_opponent_id: opponent&.id, pinned_until: opponent && PIN_TTL.from_now)
      user.save!(validate: false)
      opponent
    end
  end
end
