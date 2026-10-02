# frozen_string_literal: true

# Dex leaderboard order (Pokemons::DexLeaderboard::ORDER): rank counts and the opponent lookup read users in it.
class AddDexRankIndexToUsers < ActiveRecord::Migration[8.1]
  def change
    add_index :users, %i[battle_win_rate id], order: { battle_win_rate: :desc }, name: 'index_users_on_dex_rank'
  end
end
