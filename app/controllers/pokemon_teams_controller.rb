# frozen_string_literal: true

# Saves the Studio attack / defense roster (ordered user_pokemon ids, ≤ TEAM_SIZE).
class PokemonTeamsController < ApplicationController
  include Pokemons::GameActions

  helper Pokemons::SpriteHelper

  before_action :authenticate_user!
  pokemon_rate_limit to: 30, only: :update

  def update
    Pokemons::TeamRoster.update!(
      current_user,
      role: params.expect(:role),
      user_pokemon_ids: Array(params[:user_pokemon_ids])
    )
    head :ok
  rescue ArgumentError, ActionController::ParameterMissing
    render turbo_stream: turbo_stream_alert(t('pokemons.alerts.team_unavailable')), status: :unprocessable_content
  end
end
