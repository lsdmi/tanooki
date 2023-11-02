# frozen_string_literal: true

class UsersController < ApplicationController
  include FictionQuery

  before_action :authenticate_user!
  before_action :set_common_vars, only: %i[avatars blogs pokemons readings]

  def update
    if current_user.update(name: user_params[:name])
      current_user.update(avatar_id: user_params[:avatar_id])
      redirect_to request.referer || root_path, notice: 'Профіль оновлено.'
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: update_avatars_screen
        end
      end
    end
  end

  def avatars
    @avatars = fetch_avatars

    render 'show'
  end

  def blogs
    @pagy, @publications = pagy(@user_publications, items: 8)

    render 'show'
  end

  def pokemons
    @pokemons = pokemon_list

    if @pokemons.empty?
      @all_pokemon_count = Pokemon.count
      @all_caught_count = UserPokemon.count
    else
      @selected_pokemon = @pokemons.first
      @descendant = @selected_pokemon.pokemon.descendant
      @dex_leaderboard = User.dex_leaders.first(50)
      @battle_history = current_user.battle_logs_includes_details.sort_by { |log| -log.id }.first(50)
    end

    render 'show'
  end

  def readings
    @pagy, @fictions = pagy(fiction_list, items: 8)
    fiction_paginator = FictionPaginator.new(@pagy, @fictions, params, current_user)
    fiction_paginator.call
    @paginators = fiction_paginator.initiate

    render 'show'
  end

  def pokemon_details
    @selected_pokemon = UserPokemon.includes(:pokemon).find(params[:pokemon_id])
    if @selected_pokemon.pokemon.descendant != @selected_pokemon.pokemon
      @descendant = @selected_pokemon.pokemon.descendant
    end

    render turbo_stream: update_pokemon_details
  end

  private

  def update_avatars_screen
    turbo_stream.replace(
      'avatars-section', partial: 'users/dashboard/avatars', locals: { avatars: fetch_avatars }
    )
  end

  def update_pokemon_details
    turbo_stream.replace(
      'pokemon-details',
      partial: 'users/pokemons/details',
      locals: { selected_pokemon: @selected_pokemon, descendant: @descendant }
    )
  end

  def fiction_list
    current_user.admin? ? fiction_all_ordered_by_latest_chapter : dashboard_fiction_list
  end

  def pokemon_list
    UserPokemon.includes(pokemon: { sprite_attachment: :blob }).where(user_id: current_user).order('pokemons.dex_id')
  end

  def set_common_vars
    @fictions_size = fiction_list.size.size
    @user_publications = current_user.publications.order(created_at: :desc)
  end

  def fetch_avatars
    Rails.cache.fetch('avatars', expires_in: 1.day) do
      Avatar.includes(image_attachment: :blob).order(created_at: :desc)
    end
  end

  def user_params
    params.require(:user).permit(:avatar_id, :name)
  end
end
