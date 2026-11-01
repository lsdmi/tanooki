# frozen_string_literal: true

# Species Pokédex. Studio loads it lazily into +pokemon-dex+; full page stays for deep links.
class PokemonDexController < ApplicationController
  helper Pokemons::DexHelper,
         Pokemons::DexPageHelper,
         Pokemons::StatsHelper,
         Pokemons::SpriteHelper

  before_action :authenticate_user!

  def show
    @dex = Pokemons::Dex.new(current_user, type_key: params[:type])
    return unless turbo_frame_request_id == 'pokemon-dex'

    render partial: 'pokemon_dex/frame', locals: { dex: @dex }, layout: false
  end
end
