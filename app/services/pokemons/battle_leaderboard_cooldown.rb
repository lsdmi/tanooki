# frozen_string_literal: true

module Pokemons
  # Dex leaderboard "refresh opponent" is disabled until 4 hours after the user's last battle log update.
  class BattleLeaderboardCooldown
    def self.call(user)
      new(user).call
    end

    def initialize(user)
      @user = user
    end

    def call
      (user.last_battle_at || 1.year.ago) > 4.hours.ago
    end

    private

    attr_reader :user
  end
end
