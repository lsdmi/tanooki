# frozen_string_literal: true

# Spends a bag item from the Studio Pokémon tab.
class PokemonItemsController < ApplicationController
  include Pokemons::GameActions

  helper Pokemons::DexHelper, Pokemons::ItemsHelper, Pokemons::SpriteHelper

  before_action :authenticate_user!
  pokemon_rate_limit to: 20, only: :create

  def create
    notice = Pokemons::Items::Use.call(
      current_user,
      item_key: params.expect(:item_key),
      user_pokemon_id: params[:user_pokemon_id],
      habitat: params[:habitat]
    )
    flash_opts = notice ? { notice: } : { alert: t('pokemons.items.unavailable') }
    redirect_to studio_index_path(tab: 'pokemons'), **flash_opts
  end
end
