# frozen_string_literal: true

module Pokemons
  # Dex leaderboard ranks and opponent lookup without materializing the full table.
  class DexLeaderboard
    ORDER = Arel.sql('users.battle_win_rate DESC, users.id ASC')

    def rank_for(user)
      return unless on_leaderboard?(user)

      higher_ranked_count(user) + 1
    end

    def size
      @size ||= self.class.leader_scope.count
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
      User.where(UserPokemon.where('user_pokemons.user_id = users.id').arel.exists)
    end

    def self.ranked_scope
      leader_scope.includes(avatar: :image_attachment).order(ORDER)
    end

    private

    def higher_ranked_count(user)
      self.class.leader_scope.where(
        'users.battle_win_rate > :rate OR (users.battle_win_rate = :rate AND users.id < :id)',
        rate: user.battle_win_rate,
        id: user.id
      ).count
    end
  end
end
