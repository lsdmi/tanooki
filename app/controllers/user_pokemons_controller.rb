# frozen_string_literal: true

# Handles authenticated Pokemon catching, training, and opponent rerolls.
class UserPokemonsController < ApplicationController
  include Pokemons::GameActions

  helper Pokemons::DexHelper,
         Pokemons::StatsHelper,
         Pokemons::SpriteHelper

  before_action :authenticate_user!
  pokemon_rate_limit to: 10, only: :create
  pokemon_rate_limit to: 10, only: :training
  pokemon_rate_limit to: 5, only: :regenerate_opponent

  def create
    encounter = Pokemons::Catch.new(current_user, params[:encounter]).call
    caught = encounter.present?
    message = catch_notice(encounter)

    respond_to do |format|
      format.json { render json: { caught:, shiny: encounter&.shiny? || false, message: } }
      format.turbo_stream { render turbo_stream: [remove_pokemon, *update_notice(message)] }
    end
  end

  def training
    alert = Pokemons::Training.new(current_user, params.expect(:user_pokemon_id)).call

    if alert
      render turbo_stream: [refresh_screen, *update_notice(alert)]
    else
      render turbo_stream: refresh_error_screen
    end
  end

  def regenerate_opponent
    if Pokemons::Matchmaker.new(current_user).reroll!
      render turbo_stream: turbo_stream_list_refresh(refresh_leaderboard_card)
    else
      render turbo_stream: [refresh_leaderboard_card, *turbo_stream_alert(t('pokemons.alerts.reroll_used'))]
    end
  end

  private

  def catch_notice(encounter)
    return t('pokemons.catch.failure') if encounter.blank?
    return t('pokemons.catch.shiny_success') if encounter.shiny?

    t('pokemons.catch.success')
  end

  def pokemons
    UserPokemonListQuery.new(current_user).call.load
  end

  def refresh_error_screen
    turbo_stream_alert(t('pokemons.alerts.training_unavailable'))
  end

  def refresh_screen
    selected_pokemon = current_user.user_pokemons.find(params.expect(:user_pokemon_id))
    party = pokemons

    turbo_stream.update('pokemon-data-screen', partial: 'users/pokemons/list',
                                               locals: pokemon_screen_locals(selected_pokemon, party))
  end

  def pokemon_screen_locals(selected_pokemon, party)
    {
      pokemons: party,
      selected_pokemon:,
      evolution: selected_pokemon.next_evolution,
      attack_team: Pokemons::TeamRoster.new(current_user, :attack, party:).records,
      defense_team: Pokemons::TeamRoster.new(current_user, :defense, party:).records
    }
  end

  def remove_pokemon
    turbo_stream.remove('catch-pokemon')
  end

  def update_notice(message)
    turbo_stream_notice(message)
  end
end
