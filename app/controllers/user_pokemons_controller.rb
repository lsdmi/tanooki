# frozen_string_literal: true

class UserPokemonsController < ApplicationController
  def create
    if pokemon_catch_permitted?
      Current.user.update(pokemon_last_catch: Time.now)
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
    if Current.user.pokemon_last_training > 4.hours.ago
      render turbo_stream: refresh_error_screen
    else
      train_pokemon
      Current.user.update(pokemon_last_training: Time.now)
      render turbo_stream: [refresh_screen, update_notice(@alert)]
    end
  end

  def regenerate_opponent
    Rails.cache.delete("opponent_for_user:#{Current.user.id}")
    @pokemon_show = PokemonShow.new(Current.user)
    render turbo_stream: turbo_stream.update(
      'pokemon-leaderboard-screen',
      partial: 'users/pokemons/dex_leaderboard',
      locals: { dex_overall: @pokemon_show.dex_overall, opponent: @pokemon_show.opponent }
    )
  end

  private

  def pokemon_catch_permitted?
    Current.user.pokemon_last_catch < 4.hours.ago
  end

  def pokemons
    UserPokemon.includes(pokemon: { sprite_attachment: :blob }).where(user_id: Current.user).order('pokemons.dex_id')
  end

  def refresh_error_screen
    turbo_stream.update(
      'application-alert',
      partial: 'shared/alert',
      locals: { alert: UserPokemon::TRAINING_FRAUD_ALERT }
    )
  end

  def refresh_screen
    selected_pokemon = UserPokemon.find(params[:user_pokemon_id])

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
    user_pokemon = UserPokemon.find(params[:user_pokemon_id])

    if rand(2).zero?
      train_level(user_pokemon.pokemon)
    else
      user_pokemon.update(battle_experience: user_pokemon.battle_experience + 1) if user_pokemon.battle_experience < 100
      @alert = "#{user_pokemon.pokemon_name} набув нового бойового досвіду!"
    end
  end

  def train_level(pokemon)
    PokemonCatchService.new(pokemon_id: pokemon.id, user_id: Current.user.id).evolve
    @alert = "#{pokemon.name} набув нового якісного рівня!"
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
