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

  private

  def pokemon_catch_permitted?
    current_user.pokemon_last_catch < 4.hours.ago
  end

  def remove_pokemon
    turbo_stream.remove('catch-pokemon')
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
