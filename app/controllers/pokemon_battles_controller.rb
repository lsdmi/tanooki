# frozen_string_literal: true

class PokemonBattlesController < ApplicationController
  def start
    if possible_fraud?
      render turbo_stream: refresh_error_screen
    else
      battle_service.start_battle
      create_battle_log
      render turbo_stream: [refresh_leaders, refresh_history, remove_call]
    end
  end

  private

  def battle_history
    current_user.latest_battle_log
  end

  def battle_service
    @battle_service ||= PokemonBattleService.new(
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

    experience_distributor = PokemonExperienceDistributor.new(winner_id: battle_service.winner_id,
                                                              loser_id: battle_service.loser_id)
    experience_distributor.refresh
  end

  def defender
    User.find(params[:defender])
  end

  def defender_last_battle
    defender.battle_logs.maximum(:updated_at) || 1.year.ago
  end

  def descendant
    selected_pokemon.pokemon.descendant
  end

  def opponent
    dex_overall = User.dex_leaders

    DexLeaderboard.new(
      dex_overall.index(current_user),
      dex_overall.size
    ).call.then { |idx| dex_overall[idx] }
  end

  def pokemons
    UserPokemon.includes(pokemon: { sprite_attachment: :blob }).where(user_id: current_user).order('pokemons.dex_id')
  end

  def possible_fraud?
    self_fight || user_last_battle > 4.hours.ago || defender_last_battle > 4.hours.ago
  end

  def refresh_leaders
    turbo_stream.update(
      'pokemon-leaderboard-screen',
      partial: 'users/pokemons/dex_leaderboard',
      locals: { dex_overall: User.dex_leaders, opponent: }
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
    turbo_stream.update(
      'application-alert',
      partial: 'shared/alert',
      locals: { alert: PokemonBattleLog::POTENTIAL_FRAUD_ALERT }
    )
  end

  def selected_pokemon
    pokemons.first
  end

  def self_fight
    current_user.id == defender.id
  end

  def user_last_battle
    current_user.battle_logs.maximum(:updated_at) || 1.year.ago
  end
end
