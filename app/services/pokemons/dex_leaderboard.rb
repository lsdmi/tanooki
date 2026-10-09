# frozen_string_literal: true

module Pokemons
  # Dex leaderboard ranks, titles and the top trainers without materializing the full table. Ranked by the conservative
  # Glicko-2 rating (glicko_floor), so a new or returning trainer climbs as their deviation shrinks. One instance per
  # render: ranks and the title population are memoized.
  class DexLeaderboard
    ORDER = Arel.sql('trainer_profiles.glicko_floor DESC, trainer_profiles.user_id ASC')
    # Titles compare a trainer with those who battled this recently, until seasons exist: long-gone trainers with a
    # battle or two keep a wide deviation and a low floor, so counting them hands a newcomer's first win a high title.
    TITLE_WINDOW = 30.days
    TOP_SIZE = 20
    # Holds [user_id, place, percentile] rows; PokemonBattle deletes it after each ranked battle. The expiry only
    # drops trainers whose window ran out on a day without battles.
    TOP_CACHE_KEY = 'pokemons/dex_leaderboard/top'
    TOP_CACHE_TTL = 1.day

    TopEntry = Data.define(:user, :rank, :percentile)

    def initialize
      @ranks = {}
      @top_places = {}
    end

    def rank_for(user)
      @ranks.fetch(user.id) do
        @ranks[user.id] = (higher_ranked_count(user, self.class.leader_scope) + 1 if on_leaderboard?(user))
      end
    end

    # Place among the trainers the top lists (battled within TITLE_WINDOW); nil for anyone else.
    def top_place_for(user)
      @top_places.fetch(user.id) do
        scope = self.class.recent_scope
        @top_places[user.id] = (higher_ranked_count(user, scope) + 1 if scope.exists?(id: user.id))
      end
    end

    # Share of recently active trainers who rank strictly lower, 0...1; nil before the first battle. Ties share a
    # percentile, so a crowd on one rating never all count as the top.
    def percentile_for(user)
      profile = user.trainer_profile
      percentile_at(profile.glicko.floor) if profile.last_battle_at
    end

    def on_leaderboard?(user)
      self.class.leader_scope.exists?(id: user.id)
    end

    # The first TOP_SIZE trainers who battled within TITLE_WINDOW, with their place and title percentile: a trainer who
    # stopped keeps a high floor (deviation grows only when the next battle is rated) and would hold the top for good.
    # Users are loaded fresh, so a renamed or new avatar shows at once and a deleted user drops out.
    def self.top
      rows = Rails.cache.fetch(TOP_CACHE_KEY, expires_in: TOP_CACHE_TTL) { new.top_rows }
      users = User.includes(avatar: { image_attachment: :blob }).where(id: rows.map(&:first)).index_by(&:id)
      rows.filter_map { |id, rank, percentile| (user = users[id]) && TopEntry.new(user:, rank:, percentile:) }
    end

    def self.expire_top
      Rails.cache.delete(TOP_CACHE_KEY)
    end

    # EXISTS, not a join: a join repeats each user once per Pokémon, so every count needed DISTINCT or GROUP BY.
    def self.leader_scope
      User.joins(:trainer_profile).where(UserPokemon.where('user_pokemons.user_id = users.id').arel.exists)
    end

    # Trainers who battled within TITLE_WINDOW: the population of titles and of the top.
    def self.recent_scope
      leader_scope.where(trainer_profiles: { last_battle_at: TITLE_WINDOW.ago.. })
    end

    def top_rows
      self.class.recent_scope.order(ORDER).limit(TOP_SIZE).pluck(:id, 'trainer_profiles.glicko_floor')
          .each_with_index.map { |(id, floor), index| [id, index + 1, percentile_at(floor)] }
    end

    private

    def percentile_at(floor)
      return if active_floors.empty?

      (active_floors.bsearch_index { |other| other >= floor } || active_floors.size).fdiv(active_floors.size)
    end

    # One query for every title in the render: the floors of the TITLE_WINDOW population, ascending.
    def active_floors
      @active_floors ||= self.class.recent_scope.order('trainer_profiles.glicko_floor')
                             .pluck('trainer_profiles.glicko_floor')
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
