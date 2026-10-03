# frozen_string_literal: true

module Pokemons
  module Battle
    # Updates winner and loser battle ratings after PvP.
    class RatingUpdater
      attr_reader :winner_id, :loser_id

      RANK_RANGES = {
        1 => (-Float::INFINITY..35),
        2 => (36..55),
        3 => (56..75),
        4 => (76..90),
        5 => (91..98),
        6 => (99..Float::INFINITY)
      }.freeze

      def initialize(winner_id:, loser_id:)
        @winner_id = winner_id
        @loser_id = loser_id
      end

      # Returns the change each user got, by id (after clamping to 0..100).
      def call
        users = [User.find(winner_id), User.find(loser_id)]
        before = users.map(&:battle_win_rate)

        update_battle_rates(*users)
        users.zip(before).to_h { |user, rate| [user.id, user.battle_win_rate - rate] }
      end

      private

      def update_battle_rates(winner, loser)
        delta = user_rank(winner.battle_win_rate) - user_rank(loser.battle_win_rate)
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

      def update_rate(user, rate)
        user.update(battle_win_rate: (user.battle_win_rate + rate).clamp(0, 100))
      end

      def user_rank(battle_rate)
        RANK_RANGES.each { |rank, range| return rank if range.include?(battle_rate) }
      end
    end
  end
end
