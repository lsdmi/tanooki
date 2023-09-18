# frozen_string_literal: true

require 'test_helper'

class PokemonExperienceDistributorTest < ActiveSupport::TestCase
  def setup
    @attacker = users(:user_one)
    @defender = users(:user_two)

    @service = PokemonExperienceDistributor.new(
      winner_id: @attacker.id,
      loser_id: @defender.id
    )
  end

  test 'winner and loser battle rates are updated correctly' do
    @service.refresh

    assert_equal @attacker.battle_win_rate + 2, User.find(@attacker.id).battle_win_rate
    assert_equal @defender.battle_win_rate - 1, User.find(@defender.id).battle_win_rate
  end
end
