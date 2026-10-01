# frozen_string_literal: true

module Pokemons
  # Shared by the catch, training, reroll, and battle endpoints: per-user rate limits and the leaderboard card refresh.
  module GameActions
    extend ActiveSupport::Concern

    class_methods do
      # Declare after authenticate_user!: the limit is keyed by user, and each action gets its own counter.
      def pokemon_rate_limit(to:, only:)
        rate_limit to:, within: 1.minute, by: -> { current_user.id }, name: "pokemon-#{only}", only:,
                   with: lambda {
                     render turbo_stream: turbo_stream_alert(t('pokemons.alerts.rate_limited')),
                            status: :too_many_requests
                   }
      end
    end

    private

    def refresh_leaderboard_card
      turbo_stream.update('pokemon-leaderboard-screen', partial: 'users/pokemons/dex_leaderboard',
                                                        locals: leaderboard_card_locals(current_user))
    end

    def leaderboard_card_locals(user)
      dex_leaderboard = Pokemons::DexLeaderboard.new
      matchmaker = Pokemons::Matchmaker.new(user, leaderboard: dex_leaderboard)
      cooldown = Pokemons::BattleLeaderboardCooldown.call(user)
      { dex_leaderboard:, cooldown:,
        opponent: (matchmaker.opponent unless cooldown), can_reroll: matchmaker.reroll_available? }
    end
  end
end
