# frozen_string_literal: true

# Authenticated profile updates and Pokemon detail refreshes in Studio.
class UsersController < ApplicationController
  helper Pokemons::DexHelper,
         Pokemons::StatsHelper

  include FictionQuery
  include UserUpdateable

  before_action :authenticate_user!

  def update
    result = Users::ProfileUpdate.new(current_user, user_params).call

    if result.success?
      render turbo_stream: [*update_notice, update_navbar]
    else
      render turbo_stream: [update_avatars_screen(result.data[:avatars])]
    end
  end

  def pokemon_details
    result = Pokemons::UserPokemonDetails.new(params[:pokemon_id]).call
    render turbo_stream: update_pokemon_details(result.data)
  end

  private

  def update_notice
    turbo_stream_notice('Профіль оновлено.')
  end

  def update_navbar
    turbo_stream.update('user-dropdown', partial: 'shared/user_dropdown')
  end

  def update_avatars_screen(avatars)
    turbo_stream.update(
      'tab-content',
      partial: 'studio/tabs/profile',
      locals: { avatars: avatars }
    )
  end

  def update_pokemon_details(data)
    turbo_stream.replace(
      'pokemon-details',
      partial: 'users/pokemons/details',
      locals: { selected_pokemon: data[:selected_pokemon], descendant: data[:descendant] }
    )
  end
end
