# frozen_string_literal: true

module Pokemons
  # Dex leaderboard ranks, titles and the top trainers without materializing the full table. Ranked by the conservative
  # Glicko-2 rating (glicko_floor), so a new or returning trainer climbs as their deviation shrinks. One instance per
  # render: ranks and the title population are memoized. Titles and the top count trainers who fought in the open
  # season; +rank_for+ still counts every trainer on the board.
  class DexLeaderboard
    ORDER = Arel.sql('trainer_profiles.glicko_floor DESC, trainer_profiles.user_id ASC')
    TOP_SIZE = 20
    # Holds [user_id, place, percentile] rows; PokemonBattle deletes it after each ranked battle. Season close deletes
    # it too. The key includes the season id so a new season never reuses the previous top.
    TOP_CACHE_TTL = 1.day

    TopEntry = Data.define(:user, :rank, :percentile)

    def initialize(season: PokemonSeason.current)
      @season = season
      @ranks = {}
      @top_places = {}
    end

    def rank_for(user)
      @ranks.fetch(user.id) do
        @ranks[user.id] = (higher_ranked_count(user, self.class.leader_scope) + 1 if on_leaderboard?(user))
      end
    end

    # Place among the trainers the top lists (fought in the open season); nil for anyone else.
    def top_place_for(user)
      @top_places.fetch(user.id) do
        scope = recent_scope
        @top_places[user.id] = (higher_ranked_count(user, scope) + 1 if scope.exists?(id: user.id))
      end
    end

    # Share of trainers who fought in the open season and rank strictly lower, 0...1; nil when the trainer has not
    # fought this season. Ties share a percentile, so a crowd on one rating never all count as the top.
    def percentile_for(user)
      percentile_at(user.trainer_profile.glicko.floor) if season_floors.key?(user.id)
    end

    def on_leaderboard?(user)
      self.class.leader_scope.exists?(id: user.id)
    end

    # The first TOP_SIZE trainers who fought in the open season, with their place and title percentile. Users are
    # loaded fresh, so a renamed or new avatar shows at once and a deleted user drops out.
    def self.top
      board = new
      rows = Rails.cache.fetch(board.top_cache_key, expires_in: TOP_CACHE_TTL) { board.top_rows }
      # Names only in the Studio top list — no avatars, so skip that preload (Bullet AVOID).
      users = User.where(id: rows.map(&:first)).index_by(&:id)
      rows.filter_map { |id, rank, percentile| (user = users[id]) && TopEntry.new(user:, rank:, percentile:) }
    end

    def self.expire_top
      Rails.cache.delete(new.top_cache_key)
    end

    def self.top_cache_key
      new.top_cache_key
    end

    # EXISTS, not a join: a join repeats each user once per Pokémon, so every count needed DISTINCT or GROUP BY.
    def self.leader_scope
      User.joins(:trainer_profile).where(UserPokemon.where('user_pokemons.user_id = users.id').arel.exists)
    end

    # Trainers who fought in +season+ (either side): the population of titles and of the top.
    def self.recent_scope(season = PokemonSeason.current)
      return leader_scope.none unless season

      fought = PokemonBattle.where(pokemon_season_id: season.id)
                            .where('pokemon_battles.attacker_id = users.id OR pokemon_battles.defender_id = users.id')
      leader_scope.where(fought.arel.exists)
    end

    def top_cache_key
      "pokemons/dex_leaderboard/top/#{@season&.id || 'none'}"
    end

    def top_rows
      recent_scope.order(ORDER).limit(TOP_SIZE).pluck(:id, 'trainer_profiles.glicko_floor')
                  .each_with_index.map { |(id, floor), index| [id, index + 1, percentile_at(floor)] }
    end

    private

    def recent_scope
      self.class.recent_scope(@season)
    end

    def percentile_at(floor)
      return if active_floors.empty?

      (active_floors.bsearch_index { |other| other >= floor } || active_floors.size).fdiv(active_floors.size)
    end

    # One query for every title in the render: id → stored floor for the open-season population.
    def season_floors
      @season_floors ||= recent_scope.pluck(:id, 'trainer_profiles.glicko_floor').to_h
    end

    def active_floors
      @active_floors ||= season_floors.values.sort
    end

    # The floor is computed here, not read back: a profile just rated still holds the generated column's old value.
    # MySQL computes it with the same double arithmetic, so the comparison is exact.
    def higher_ranked_count(user, scope)
      scope.where(
        'trainer_profiles.glicko_floor > :floor OR ' \
        '(trainer_profiles.glicko_floor = :floor AND trainer_profiles.user_id < :id)',
        floor: user.trainer_profile.glicko.floor,
        id: user.id
      ).count
    end
  end
end
