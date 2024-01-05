# frozen_string_literal: true

class PokemonExperienceDistributor
  attr_reader :winner_id, :loser_id

  RANK_RANGES = {
    1 => (-Float::INFINITY..20),
    2 => (21..40),
    3 => (41..60),
    4 => (61..80),
    5 => (81..90),
    6 => (91..Float::INFINITY)
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
    winner_rate = winner.battle_win_rate
    loser_rate = loser.battle_win_rate
    rank_difference = user_rank(winner_rate) - user_rank(loser_rate)

    case rank_difference <=> 0
    when 0
      update_equal_rank(winner, loser)
    when -1
      update_lower_rank(winner, loser)
    end
  end

  def update_equal_rank(user1, user2)
    update_rate(user1, 2)
    update_rate(user2, -1)
  end

  def update_lower_rank(winner, loser)
    update_rate(winner, 3)
    update_rate(loser, -2)
  end

  def update_rate(user, rate)
    new_rate = [user.battle_win_rate + rate, 100].min
    user.update(battle_win_rate: new_rate)
  end

  def user_rank(battle_rate)
    RANK_RANGES.each { |rank, range| return rank if range.include?(battle_rate) }
  end
end
