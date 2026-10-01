# frozen_string_literal: true

# Handles authenticated Pokemon catching, training, and opponent rerolls.
class UserPokemonsController < ApplicationController
  include Pokemons::GameActions

  helper Pokemons::DexHelper,
         Pokemons::StatsHelper

  before_action :authenticate_user!
  pokemon_rate_limit to: 10, only: :create
  pokemon_rate_limit to: 10, only: :training
  pokemon_rate_limit to: 5, only: :regenerate_opponent

  def create
    encounter = claim_encounter if pokemon_catch_permitted?

    if encounter
      current_user.update(pokemon_last_catch: Time.current)
      Pokemons::CollectionUpdater.new(pokemon_id: encounter.pokemon_id, user_id: current_user.id).trap
      render turbo_stream: [remove_pokemon, *update_notice(UserPokemon::SUCCESS_MESSSAGE)]
    else
      render turbo_stream: [remove_pokemon, *update_notice(UserPokemon::FAILURE_MESSSAGE)]
    end
  end

  def training
    if current_user.pokemon_training_on_cooldown?
      render turbo_stream: refresh_error_screen
    else
      train_pokemon
      current_user.update(pokemon_last_training: Time.current)
      render turbo_stream: [refresh_screen, *update_notice(@alert)]
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

  def pokemon_catch_permitted?
    current_user.pokemon_catch_permitted?
  end

  def claim_encounter
    encounter = current_user.pokemon_encounters.for_catch_token(params[:encounter].to_s)
    encounter if encounter&.claim!
  end

  def pokemons
    UserPokemon.includes(pokemon: { sprite_attachment: :blob }).where(user_id: current_user).order('pokemons.dex_id')
  end

  def refresh_error_screen
    turbo_stream_alert(UserPokemon::TRAINING_FRAUD_ALERT)
  end

  def refresh_screen
    selected_pokemon = current_user.user_pokemons.find(params.expect(:user_pokemon_id))

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
    @alert = current_user.user_pokemons.find(params.expect(:user_pokemon_id)).train![:alert]
  end

  def update_notice(message)
    turbo_stream_notice(message)
  end
end
