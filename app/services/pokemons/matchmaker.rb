# frozen_string_literal: true

module Pokemons
  # Pins one battle opponent per user, so the battle endpoint fights whoever the page showed, never an id from the form.
  # The opponent is one of the active trainers with the nearest Glicko-2 rating (the window widens by itself: it is
  # the nearest few, however far), skipping the attacker's recent defenders while anyone else is available.
  class Matchmaker
    PIN_TTL = 24.hours

    def initialize(user, leaderboard: DexLeaderboard.new)
      @user = user
      @leaderboard = leaderboard
    end

    # Trainers on the leaderboard who attacked, caught or trained within Balance::ACTIVE_WINDOW.
    def self.active_scope(since: Balance::ACTIVE_WINDOW.ago)
      board = DexLeaderboard.leader_scope
      attacked = PokemonBattle.where('pokemon_battles.attacker_id = users.id').where(created_at: since..).arel.exists
      board.where(trainer_profiles: { last_catch_at: since.. })
           .or(board.where(trainer_profiles: { last_training_at: since.. }))
           .or(board.where(attacked))
    end

    # The current pin, or nil. Never pins anyone, so a battle request cannot pick its own opponent.
    def pinned_opponent
      return unless profile.pinned_opponent_id && profile.pinned_until&.future?

      opponent = User.find_by(id: profile.pinned_opponent_id)
      opponent if opponent && opponent.id != user.id && @leaderboard.on_leaderboard?(opponent)
    end

    # The current pin, pinning a fresh opponent when it is missing, expired, or no longer valid.
    def opponent
      pinned_opponent || profile.with_lock { pinned_opponent || pin(pick) }
    end

    def reroll_available?
      return false if BattleLeaderboardCooldown.call(user)

      profile.opponent_rerolled_at.nil? || profile.opponent_rerolled_at <= Balance::BATTLE_COOLDOWN.ago
    end

    # True when the reroll was spent; false when it was already used this window or the team is resting. Keeps the
    # current opponent when there is no one else.
    def reroll!
      profile.with_lock do
        next false unless reroll_available?

        profile.opponent_rerolled_at = Time.current
        pin(pick(excluding: [profile.pinned_opponent_id]) || pinned_opponent)
        true
      end
    end

    def release!
      pin(nil)
    end

    private

    attr_reader :user

    def profile = user.trainer_profile

    def pick(excluding: [])
      excluding = [user.id, *excluding].compact
      nearest(excluding + recent_opponents) || nearest(excluding)
    end

    def nearest(excluding)
      distance = ['ABS(trainer_profiles.glicko_rating - ?)', profile.glicko_rating]
      self.class.active_scope.where.not(id: excluding)
          .order(Arel.sql(ActiveRecord::Base.sanitize_sql_array(distance)), :id)
          .limit(Balance::NEAREST_OPPONENTS).to_a.sample
    end

    def recent_opponents
      PokemonBattle.where(attacker_id: user.id).order(created_at: :desc).limit(Balance::RECENT_OPPONENTS)
                   .pluck(:defender_id)
    end

    def pin(opponent)
      profile.update!(pinned_opponent_id: opponent&.id, pinned_until: opponent && PIN_TTL.from_now)
      opponent
    end
  end
end
