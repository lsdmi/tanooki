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
      @pokemon = Pokemon.new(pokemon_attributes)

      if @pokemon.save
        sync_types if type_ids_submitted?
        redirect_to admin_pokemons_path, notice: t('admin.pokemons.notices.create_success')
      else
        render 'admin/pokemons/new', status: :unprocessable_content
      end
    end

    def update
      if @pokemon.update(pokemon_attributes)
        sync_types if type_ids_submitted?
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

      render turbo_stream: turbo_stream_list_refresh(refresh_list)
    end

    private

    def sync_types
      existing_type_ids = @pokemon.types.ids

      (permitted_type_ids - existing_type_ids)
        .each { |pokemon_type_id| @pokemon.pokemon_type_relations.create(pokemon_type_id:) }
      (existing_type_ids - permitted_type_ids)
        .each { |pokemon_type_id| @pokemon.pokemon_type_relations.find_by(pokemon_type_id:).destroy }
    end

    def permitted_type_ids
      @permitted_type_ids ||= Pokemons::PermittedTypeIds.filter(pokemon_params[:type_ids])
    end

    def type_ids_submitted?
      pokemon_params.key?(:type_ids)
    end

    def pokemon_attributes
      pokemon_params.except(:type_ids)
    end

    def set_types
      @types = PokemonType.order(:name)
    end

    def pokemon_params
      params.expect(
        pokemon: [
          :ancestor_id, :descendant_id, :descendant_level, :dex_id, :name, :power_level, :rarity, :sprite,
          { type_ids: [] }
        ]
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
      @pokemon = Pokemon.find(params.expect(:id))
    end
  end
end
