# frozen_string_literal: true

module Pokemons
  # True for Balance::BATTLE_COOLDOWN after the user's last battle (as attacker or defender).
  class BattleLeaderboardCooldown
    def self.call(user)
      new(user).call
    end

    def initialize(user)
      @user = user
    end

    def call
      (user.last_battle_at || 1.year.ago) > Balance::BATTLE_COOLDOWN.ago
    end

    private

    attr_reader :user
  end
end
