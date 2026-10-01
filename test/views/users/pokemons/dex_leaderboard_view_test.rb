# frozen_string_literal: true

require 'test_helper'

class DexLeaderboardViewTest < ActionView::TestCase
  helper Pokemons::DexHelper

  test 'no opponent renders the empty state without a reroll or battle button' do
    render partial: 'users/pokemons/dex_leaderboard',
           locals: { dex_leaderboard: Pokemons::DexLeaderboard.new, opponent: nil, cooldown: false, can_reroll: true }

    assert_includes rendered, I18n.t('pokemons.opponent.empty')
    assert_not_includes rendered, regenerate_pokemon_opponent_path
    assert_not_includes rendered, battle_start_path
  end
end
