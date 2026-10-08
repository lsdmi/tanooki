# frozen_string_literal: true

module Pokemons
  # Dex leaderboard ranks and opponent lookup without materializing the full table. Ranked by the conservative
  # Glicko-2 rating (glicko_floor), so a new or returning trainer climbs as their deviation shrinks.
  class DexLeaderboard
    ORDER = Arel.sql('trainer_profiles.glicko_floor DESC, trainer_profiles.user_id ASC')
    # Titles compare a trainer with those who battled this recently, until seasons exist: long-gone trainers with a
    # battle or two keep a wide deviation and a low floor, so counting them hands a newcomer's first win a high title.
    TITLE_WINDOW = 30.days

    def rank_for(user)
      return unless on_leaderboard?(user)

      higher_ranked_count(user) + 1
    end

    def size
      @size ||= self.class.leader_scope.count
    end

    # Share of recently active trainers who rank strictly lower, 0...1; nil before the first battle. Ties share a
    # percentile, so a crowd on one rating never all count as the top.
    def percentile_for(user)
      profile = user.trainer_profile
      return unless profile.last_battle_at && active_size.positive?

      active.where(trainer_profiles: { glicko_floor: ...profile.glicko.floor }).count.fdiv(active_size)
    end

    def user_at_index(index)
      self.class.ranked_scope.offset(index).first
    end

    def opponent_for(user)
      rank_index = rank_for(user)
      return unless rank_index

      sampled_index = DexRankSampler.new(rank_index - 1, size).call
      return unless sampled_index

      user_at_index(sampled_index)
    end

    def on_leaderboard?(user)
      self.class.leader_scope.exists?(id: user.id)
    end

    # EXISTS, not a join: a join repeats each user once per Pokémon, so every count needed DISTINCT or GROUP BY.
    def self.leader_scope
      User.joins(:trainer_profile).where(UserPokemon.where('user_pokemons.user_id = users.id').arel.exists)
    end

    def self.ranked_scope
      leader_scope.includes(:trainer_profile, avatar: :image_attachment).order(ORDER)
    end

    private

    def active = self.class.leader_scope.where(trainer_profiles: { last_battle_at: TITLE_WINDOW.ago.. })

    def active_size
      @active_size ||= active.count
    end

    # The floor is computed here, not read back: a profile just rated still holds the generated column's old value.
    # MySQL computes it with the same double arithmetic, so the comparison is exact.
    def higher_ranked_count(user)
      self.class.leader_scope.where(
        'trainer_profiles.glicko_floor > :floor OR ' \
        '(trainer_profiles.glicko_floor = :floor AND trainer_profiles.user_id < :id)',
        floor: user.trainer_profile.glicko.floor,
        id: user.id
      ).count
    end
  end
end
