# frozen_string_literal: true

module Admin
  class PokemonsController < ApplicationController
    before_action :authenticate_user!, :verify_user_permissions
    before_action :set_pokemon, only: %i[edit update destroy]

    def index
      @pagy, @pokemons = pagy(Pokemon.includes(sprite_attachment: :blob).order(:name), items: 10)
    end

    def create
      @pokemon = Pokemon.new(pokemon_params)

      if @pokemon.save
        redirect_to admin_pokemons_path, notice: 'Дані про покемона додано.'
      else
        render 'admin/pokemons/new', status: :unprocessable_entity
      end
    end

    def update
      if @pokemon.update(pokemon_params)
        redirect_to admin_pokemons_path, notice: 'Дані про покемона оновлено.'
      else
        render 'admin/pokemons/edit', status: :unprocessable_entity
      end
    end

    def destroy
      @pokemon.destroy
      @pagy, @pokemons = pagy(
        Pokemon.includes(sprite_attachment: :blob).order(:name),
        items: 10,
        request_path: admin_pokemons_path,
        page: params[:page] || 1
      )

      render turbo_stream: refresh_list
    end

    def new
      @pokemon = Pokemon.new
    end

    def edit; end

    private

    def pokemon_params
      params.require(:pokemon).permit(
        :name, :power_level, :rarity, :sprite
      )
    end

    def refresh_list
      turbo_stream.update(
        'pokemons-list',
        partial: 'admin/pokemons/list',
        locals: { pokemons: @pokemons, pagy: @pagy }
      )
    end

    def set_pokemon
      @pokemon = Pokemon.find(params[:id])
    end
  end
end
