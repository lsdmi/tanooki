# frozen_string_literal: true

module Pokemons
  module Battle
    # Updates the winner's and loser's trainer profile ratings after PvP.
    class RatingUpdater
      attr_reader :winner, :loser

      RANK_RANGES = {
        1 => (-Float::INFINITY..35),
        2 => (36..55),
        3 => (56..75),
        4 => (76..90),
        5 => (91..98),
        6 => (99..Float::INFINITY)
      }.freeze

      def initialize(winner:, loser:)
        @winner = winner
        @loser = loser
      end

      # Returns the change each user got, by user id (after clamping to 0..100).
      def call
        profiles = [winner, loser]
        before = profiles.map(&:rating)

        update_battle_rates(winner, loser)
        profiles.zip(before).to_h { |profile, rating| [profile.user_id, profile.rating - rating] }
      end

      private

      def update_battle_rates(winner, loser)
        delta = user_rank(winner.rating) - user_rank(loser.rating)
        case delta <=> 0
        when 1 then update_higher_rank(winner, loser)
        when 0 then update_equal_rank(winner, loser)
        when -1 then update_lower_rank(winner, loser)
        end
      end

      def update_higher_rank(winner, loser)
        update_rate(winner, 1)
        update_rate(loser, -1)
      end

      def update_equal_rank(user1, user2)
        update_rate(user1, 2)
        update_rate(user2, -2)
      end

      def update_lower_rank(winner, loser)
        update_rate(winner, 3)
        update_rate(loser, -3)
      end

      def update_rate(profile, rate)
        profile.update!(rating: (profile.rating + rate).clamp(0, 100))
      end

      def user_rank(battle_rate)
        RANK_RANGES.each { |rank, range| return rank if range.include?(battle_rate) }
      end
    end
  end
end
