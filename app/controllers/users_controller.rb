# frozen_string_literal: true

class UsersController < ApplicationController
  include FictionQuery
  include UserUpdateable

  before_action :authenticate_user!

  def update
    result = UserUpdateService.new(current_user, user_params).call

    if result.success?
      render turbo_stream: [
        update_notice,
        update_sidebar,
        update_navbar
      ]
    else
      render turbo_stream: [
        update_avatars_screen(result.data[:avatars])
      ]
    end
  end

  def pokemon_details
    result = PokemonDetailsService.new(params[:pokemon_id]).call
    render turbo_stream: update_pokemon_details(result.data)
  end

  private

  def update_notice
    turbo_stream.update(
      'application-notice',
      partial: 'shared/notice',
      locals: { notice: 'Профіль оновлено.' }
    )
  end

  def update_sidebar
    turbo_stream.replace('sidebar', partial: 'users/dashboard/sidebar')
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
