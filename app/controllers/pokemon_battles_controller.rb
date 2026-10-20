# frozen_string_literal: true

# Starts authenticated Pokemon battles and serves the public shareable battle page.
class PokemonBattlesController < ApplicationController
  include Pokemons::GameActions

  helper Pokemons::DexHelper,
         Pokemons::StatsHelper

  before_action :authenticate_user!, only: :start
  before_action :set_battle, only: %i[show og]
  pokemon_rate_limit to: 5, only: :start

  def start
    if Pokemons::BattleStart.new(current_user).call == :fought
      current_user.reload
      render turbo_stream: turbo_stream_with_cleared_flash(refresh_leaderboard_card, refresh_history, remove_call,
                                                           refresh_top)
    else
      render turbo_stream: turbo_stream_alert(t('pokemons.alerts.battle_unavailable'))
    end
  end

  def show
    @pokemon_battle = @battle
  end

  def og
    expires_in 1.week, public: true
    send_data Pokemons::BattleOgImage.new(@battle).png, type: 'image/png', disposition: 'inline',
                                                        filename: 'battle.png'
  end

  private

  def set_battle
    @battle = PokemonBattle.by_sqid(params[:id]).includes(:attacker, :defender, :winner).first!
  end

  def refresh_history
    turbo_stream.update(
      'pokemon-history-list',
      partial: 'users/pokemons/history_record',
      locals: { battle: current_user.latest_battle }
    )
  end

  def refresh_top
    turbo_stream.replace('pokemon-top-trainers', partial: 'users/pokemons/top_trainers',
                                                 locals: { top: Pokemons::DexLeaderboard.top,
                                                           dex_leaderboard: Pokemons::DexLeaderboard.new })
  end

  def remove_call
    turbo_stream.remove('pokemon-history-call')
  end
end
