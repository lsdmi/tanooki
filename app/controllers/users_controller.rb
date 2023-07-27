# frozen_string_literal: true

class UsersController < ApplicationController
  include FictionQuery

  before_action :authenticate_user!
  before_action :set_common_vars, only: %i[avatars blogs pokemons readings]

  def update_avatar
    current_user.update(avatar_id: params[:user][:avatar_id])
    redirect_to request.referer || root_path, notice: 'Портретик оновлено.'
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
      @dex_leaderboard = User.dex_leaders.excluding(User.admins)
    end

    render 'show'
  end

  def readings
    @pagy, @fictions = pagy(fiction_list, items: 8)
    @random_reading = Fiction.all.sample
    fiction_paginator = FictionPaginator.new(@pagy, @fictions, params, current_user)
    fiction_paginator.call
    @paginators = fiction_paginator.initiate

    render 'show'
  end

  private

  def fiction_list
    current_user.admin? ? fiction_all_ordered_by_latest_chapter : dashboard_fiction_list
  end

  def pokemon_list
    current_user
      .pokemons
      .includes(sprite_attachment: :blob)
      .select('pokemons.*, COUNT(user_pokemons.pokemon_id) as duplicates_count')
      .group(:pokemon_id)
      .order('MAX(user_pokemons.created_at) DESC')
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
end
