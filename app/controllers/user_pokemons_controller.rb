# frozen_string_literal: true

class UserPokemonsController < ApplicationController
  def create
    if pokemon_catch_permitted?
      current_user.update(pokemon_last_catch: Time.now)
      PokemonCatchService.new(
        pokemon_id: user_pokemon_params[:pokemon_id],
        user_id: user_pokemon_params[:user_id]
      ).trap
      render turbo_stream: [remove_pokemon, update_notice(UserPokemon::SUCCESS_MESSSAGE)]
    else
      render turbo_stream: [remove_pokemon, update_notice(UserPokemon::FAILURE_MESSSAGE)]
    end
  end

  def training
    if current_user.pokemon_last_training > 4.hours.ago
      render turbo_stream: refresh_error_screen
    else
      train_pokemon
      current_user.update(pokemon_last_training: Time.now)
      render turbo_stream: [refresh_screen, update_notice(@alert)]
    end
  end

  private

  def pokemon_catch_permitted?
    current_user.pokemon_last_catch < 4.hours.ago
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
    turbo_stream.update(
      'pokemon-data-screen',
      partial: 'users/pokemons/list',
      locals: { pokemons:, selected_pokemon: pokemons.first, descendant: pokemons.first.pokemon.descendant }
    )
  end

  def remove_pokemon
    turbo_stream.remove('catch-pokemon')
  end

  def train_pokemon
    user_pokemon = UserPokemon.find(params[:user_pokemon_id])

    if rand(2).zero?
      PokemonCatchService.new(pokemon_id: user_pokemon.pokemon.id, user_id: current_user.id).evolve
      @alert = UserPokemon::EVOLUTION_TRAINING_SUCCESS
    else
      user_pokemon.update(battle_experience: user_pokemon.battle_experience + 1)
      @alert = UserPokemon::BATTLE_TRAINING_SUCCESS
    end
  end

  def update_notice(message)
    turbo_stream.update(
      'application-notice',
      partial: 'shared/notice',
      locals: { notice: message }
    )
  end

  def user_pokemon_params
    params.require(:user_pokemon).permit(:pokemon_id, :user_id)
  end
end
