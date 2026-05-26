# frozen_string_literal: true

# Handles authenticated Pokemon catching, training, and opponent refreshes.
class UserPokemonsController < ApplicationController
  before_action :authenticate_user!

  def create
    if pokemon_catch_permitted?
      current_user.update(pokemon_last_catch: Time.current)
      Pokemons::CollectionUpdater.new(
        pokemon_id: user_pokemon_params[:pokemon_id],
        user_id: current_user.id
      ).trap
      render turbo_stream: [remove_pokemon, update_notice(UserPokemon::SUCCESS_MESSSAGE)]
    else
      render turbo_stream: [remove_pokemon, update_notice(UserPokemon::FAILURE_MESSSAGE)]
    end
  end

  def training
    if current_user.pokemon_training_on_cooldown?
      render turbo_stream: refresh_error_screen
    else
      train_pokemon
      current_user.update(pokemon_last_training: Time.current)
      render turbo_stream: [refresh_screen, update_notice(@alert)]
    end
  end

  def regenerate_opponent
    Rails.cache.delete("opponent_for_user:#{current_user.id}")
    @pokemon_show = Pokemons::StudioTab.new(current_user)
    render turbo_stream: turbo_stream.update(
      'pokemon-leaderboard-screen',
      partial: 'users/pokemons/dex_leaderboard',
      locals: { dex_overall: @pokemon_show.dex_overall, opponent: @pokemon_show.opponent,
                cooldown: @pokemon_show.leaderboard_cooldown? }
    )
  end

  private

  def pokemon_catch_permitted?
    current_user.pokemon_catch_permitted?
  end

  def pokemons
    UserPokemon.includes(pokemon: { sprite_attachment: :blob }).where(user_id: current_user).order('pokemons.dex_id')
  end

  def refresh_error_screen
    turbo_stream.update(
      'application-alert',
      partial: 'shared/alert',
      locals: { alert: UserPokemon::TRAINING_FRAUD_ALERT }
    )
  end

  def refresh_screen
    selected_pokemon = current_user.user_pokemons.find(params[:user_pokemon_id])

    turbo_stream.update(
      'pokemon-data-screen',
      partial: 'users/pokemons/list',
      locals: { pokemons:, selected_pokemon:, descendant: selected_pokemon.pokemon.descendant }
    )
  end

  def remove_pokemon
    turbo_stream.remove('catch-pokemon')
  end

  def train_pokemon
    @alert = current_user.user_pokemons.find(params[:user_pokemon_id]).train![:alert]
  end

  def update_notice(message)
    turbo_stream.update(
      'application-notice',
      partial: 'shared/notice',
      locals: { notice: message }
    )
  end

  def user_pokemon_params
    params.expect(user_pokemon: [:pokemon_id])
  end
end
