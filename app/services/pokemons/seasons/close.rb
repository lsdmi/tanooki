# frozen_string_literal: true

module Pokemons
  module Seasons
    # Closes an open season whose last day has passed: writes season_results for everyone who fought in it, soft-resets
    # every trainer who has ever battled, expires the top cache, and opens the next season. Idempotent when nothing is
    # due.
    class Close
      def self.call(at: Time.current)
        new(at:).call
      end

      def initialize(at: Time.current)
        @at = at
      end

      # :closed, :none, or :already when the current season has not ended yet.
      def call
        season = PokemonSeason.current
        return :none unless season
        return :already if season.ends_on >= at.to_date

        close!(season) ? :closed : :none
      end

      private

      attr_reader :at

      def close!(season)
        ApplicationRecord.transaction do
          season.lock!
          season.reload
          next false if season.closed?

          record_close(season)
          true
        end
      end

      def record_close(season)
        persist_standings(season)
        soft_reset_ratings
        season.update!(closed_at: at)
        DexLeaderboard.expire_top
        Open.next!(at:)
      end

      def persist_standings(season)
        leaderboard = DexLeaderboard.new(season:)
        rows = standings(season)
        users = User.includes(:trainer_profile).where(id: rows.map(&:first)).index_by(&:id)
        rows.each_with_index { |row, index| write_result(season, leaderboard, users, row, index) }
      end

      def write_result(season, leaderboard, users, row, index)
        user_id, floor, battles, wins = row
        user = users.fetch(user_id)
        profile = user.trainer_profile
        SeasonResult.create!(
          pokemon_season: season, user:, place: index + 1, battles:, wins:,
          percentile: leaderboard.percentile_for(user) || 0.0, glicko_floor: floor,
          glicko_rating: profile.glicko_rating, glicko_deviation: profile.glicko_deviation
        )
      end

      # One row per fighter, ordered like the top: glicko_floor DESC, user_id ASC.
      def standings(season)
        battles = battle_counts(season)
        wins = PokemonBattle.where(pokemon_season_id: season.id).group(:winner_id).count
        DexLeaderboard.recent_scope(season).order(DexLeaderboard::ORDER)
                      .pluck(:id, 'trainer_profiles.glicko_floor')
                      .map { |id, floor| [id, floor, battles.fetch(id, 0), wins.fetch(id, 0)] }
      end

      def battle_counts(season)
        counts = Hash.new(0)
        PokemonBattle.where(pokemon_season_id: season.id).pluck(:attacker_id, :defender_id).each do |attacker, defender|
          counts[attacker] += 1
          counts[defender] += 1
        end
        counts
      end

      def soft_reset_ratings
        TrainerProfile.where.not(last_battle_at: nil).find_each do |profile|
          profile.update!(glicko: SoftReset.apply(profile.glicko))
        end
      end
    end
  end
end
