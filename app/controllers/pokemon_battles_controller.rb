# frozen_string_literal: true

# Starts authenticated Pokemon battles and refreshes related battle UI.
class PokemonBattlesController < ApplicationController
  include Pokemons::GameActions

  helper Pokemons::DexHelper

  before_action :authenticate_user!
  pokemon_rate_limit to: 5, only: :start

  def start
    if Pokemons::BattleStart.new(current_user).call == :fought
      current_user.reload
      render turbo_stream: turbo_stream_with_cleared_flash(refresh_leaderboard_card, refresh_history, remove_call)
    else
      render turbo_stream: turbo_stream_alert(t('pokemons.alerts.battle_unavailable'))
    end
  end

  private

  def refresh_history
    turbo_stream.update(
      'pokemon-history-list',
      partial: 'users/pokemons/history_record',
      locals: { battle: current_user.latest_battle }
    )
  end

  def remove_call
    turbo_stream.remove('pokemon-history-call')
  end
end
