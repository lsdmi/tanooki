# frozen_string_literal: true

class UserPokemonsController < ApplicationController
  def create
    return unless session[:pokemon_catch_permitted].present?

    UserPokemon.create(user_pokemon_params)

    render turbo_stream: [remove_pokemon, update_notice]
  end

  private

  def remove_pokemon
    turbo_stream.remove('catch-pokemon')
  end

  def update_notice
    turbo_stream.update(
      'application-notice',
      partial: 'shared/notice',
      locals: { notice: 'Вітаємо, із поповненням у команді!' }
    )
  end

  def user_pokemon_params
    params.require(:user_pokemon).permit(:pokemon_id, :user_id)
  end
end
