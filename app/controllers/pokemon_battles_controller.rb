# frozen_string_literal: true

# Starts authenticated Pokemon battles and refreshes related battle UI.
class PokemonBattlesController < ApplicationController
  helper Pokemons::DexHelper

  before_action :authenticate_user!

  def start
    if possible_fraud?
      render turbo_stream: refresh_error_screen
    else
      battle_service.start_battle
      create_battle_log
      finish_battle
      render turbo_stream: turbo_stream_with_cleared_flash(refresh_leaders, refresh_history, remove_call)
    end
  end

  private

  def battle_history
    current_user.latest_battle_log
  end

  def battle_service
    @battle_service ||= Pokemons::BattleRun.new(
      attacker_pokemons: current_user.user_pokemons,
      defender_pokemons: defender.user_pokemons,
      attacker_id: current_user.id,
      defender_id: params[:defender]
    )
  end

  def create_battle_log
    PokemonBattleLog.create(
      attacker_id: current_user.id,
      defender_id: params[:defender],
      winner_id: battle_service.winner_id,
      details: battle_service.fight_details
    )

    rating_updater = Pokemons::Battle::RatingUpdater.new(winner_id: battle_service.winner_id,
                                                         loser_id: battle_service.loser_id)
    rating_updater.call
  end

  def defender
    User.find(params[:defender])
  end

  def descendant
    selected_pokemon.pokemon.descendant
  end

  def opponent
    dex_leaderboard = Pokemons::DexLeaderboard.new
    dex_leaderboard.opponent_for(current_user)
  end

  def pokemons
    UserPokemon.includes(pokemon: { sprite_attachment: :blob }).where(user_id: current_user).order('pokemons.dex_id')
  end

  def possible_fraud?
    self_fight? || user_last_battle > 4.hours.ago
  end

  def finish_battle
    current_user.reload
    Rails.cache.delete("user:#{current_user.id}:battle_history")
    Rails.cache.delete("opponent_for_user:#{current_user.id}")
  end

  def refresh_leaders
    turbo_stream.update(
      'pokemon-leaderboard-screen',
      partial: 'users/pokemons/dex_leaderboard',
      locals: { dex_leaderboard: Pokemons::DexLeaderboard.new, opponent:,
                cooldown: Pokemons::BattleLeaderboardCooldown.call(current_user) }
    )
  end

  def refresh_history
    turbo_stream.update(
      'pokemon-history-list',
      partial: 'users/pokemons/history_record',
      locals: { battle_log: battle_history }
    )
  end

  def remove_call
    turbo_stream.remove('pokemon-history-call')
  end

  def refresh_error_screen
    turbo_stream_alert(PokemonBattleLog::POTENTIAL_FRAUD_ALERT)
  end

  def selected_pokemon
    pokemons.first
  end

  def self_fight?
    current_user.id == defender.id
  end

  def user_last_battle
    current_user.last_battle_at || 1.year.ago
  end
end
