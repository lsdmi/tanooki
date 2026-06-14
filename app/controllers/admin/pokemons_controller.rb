# frozen_string_literal: true

module Admin
  # Manages the Pokemon catalog (dex entries, types, sprites) for privileged users.
  class PokemonsController < ApplicationController
    before_action :authenticate_user!, :verify_user_permissions
    before_action :set_pokemon, only: %i[edit update destroy]
    before_action :set_types, only: %i[new create edit update]

    def index
      @pagy, @pokemons = pagy(Pokemon.includes(sprite_attachment: :blob).order(:dex_id), limit: 10)
    end

    def new
      @pokemon = Pokemon.new
    end

    def edit; end

    def create
      @pokemon = Pokemon.new(pokemon_params)

      if @pokemon.save
        manage_types if params[:pokemon][:type_ids]
        redirect_to admin_pokemons_path, notice: t('admin.pokemons.notices.create_success')
      else
        render 'admin/pokemons/new', status: :unprocessable_content
      end
    end

    def update
      if @pokemon.update(pokemon_params)
        manage_types if params[:pokemon][:type_ids]
        redirect_to admin_pokemons_path, notice: t('admin.pokemons.notices.update_success')
      else
        render 'admin/pokemons/edit', status: :unprocessable_content
      end
    end

    def destroy
      @pokemon.destroy
      @pagy, @pokemons = pagy(
        Pokemon.includes(sprite_attachment: :blob).order(:name),
        limit: 10,
        request_path: admin_pokemons_path,
        page: params[:page] || 1
      )

      render turbo_stream: refresh_list
    end

    private

    def manage_types
      existing_type_ids = @pokemon.types.ids

      (pokemon_types_ids - existing_type_ids)
        .each { |pokemon_type_id| @pokemon.pokemon_type_relations.create(pokemon_type_id:) }
      (existing_type_ids - pokemon_types_ids)
        .each { |pokemon_type_id| @pokemon.pokemon_type_relations.find_by(pokemon_type_id:).destroy }
    end

    def pokemon_types_ids
      @pokemon_types_ids ||= params[:pokemon][:type_ids].compact_blank.map(&:to_i)
    end

    def set_types
      @types = PokemonType.order(:name)
    end

    def pokemon_params
      params.expect(
        pokemon: %i[ancestor_id descendant_id descendant_level dex_id name power_level rarity sprite]
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
