# frozen_string_literal: true

module Pokemons
  module Battle
    # Rates one PvP battle with Glicko-2 and saves both trainer profiles. Both sides are rated from their ratings
    # before the battle, each with the deviation it has grown since its own last battle. The defender gets the full
    # change though it did not choose to fight: the simulator showed that damping it only made idle trainers' ratings
    # less accurate, and a run of attackers on an idle top trainer does not drain it.
    class RatingUpdater
      def initialize(winner:, loser:, at: Time.current)
        @winner = winner
        @loser = loser
        @at = at
      end

      # Returns the rating change each user got, rounded, by user id.
      def call
        before = [@winner, @loser].index_with { |profile| profile.glicko.idle(profile.idle_periods(@at)) }
        rated = { @winner => rate(@winner, before[@loser], 1), @loser => rate(@loser, before[@winner], 0) }
        rated.to_h { |profile, rating| [profile.user_id, save(profile, rating)] }
      end

      private

      def rate(profile, opponent, score)
        Ratings::Glicko2.rate(profile.glicko, [[opponent, score]], periods: profile.idle_periods(@at))
      end

      def save(profile, rating)
        change = (rating.rating - profile.glicko_rating).round
        profile.update!(glicko: rating)
        change
      end
    end
  end
end
