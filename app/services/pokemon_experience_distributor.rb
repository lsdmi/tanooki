# frozen_string_literal: true

class PokemonExperienceDistributor
  attr_reader :winner_id, :loser_id

  RANK_RANGES = {
    1 => (0..30),
    2 => (31..50),
    3 => (51..70),
    4 => (71..90),
    5 => (91..Float::INFINITY)
  }.freeze

  def initialize(winner_id:, loser_id:)
    @winner_id = winner_id
    @loser_id = loser_id
  end

  def refresh
    winner = User.find(winner_id)
    loser = User.find(loser_id)

    update_battle_rates(winner, loser)
  end

  private

  def update_battle_rates(winner, loser)
    winner_battle_rate = winner.battle_win_rate
    loser_battle_rate = loser.battle_win_rate

    winner_rank = user_rank(winner_battle_rate)
    loser_rank = user_rank(loser_battle_rate)

    rank_difference = winner_rank - loser_rank

    if rank_difference.zero?
      winner.update(battle_win_rate: winner_battle_rate + 2)
      loser.update(battle_win_rate: loser_battle_rate - 1)
    elsif rank_difference.negative?
      winner.update(battle_win_rate: winner_battle_rate + 3)
      loser.update(battle_win_rate: loser_battle_rate - 2)
    end
  end

  def user_rank(battle_rate)
    RANK_RANGES.each { |rank, range| return rank if range.include?(battle_rate) }
  end
end