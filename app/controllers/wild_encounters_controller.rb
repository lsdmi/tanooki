# frozen_string_literal: true

# Fills the wild pop-up frame once the page is on screen; see Pokemons::WildCatch.
class WildEncountersController < ApplicationController
  helper Pokemons::SpriteHelper

  def show
    @wild_encounter = Pokemons::WildCatch.new(user: current_user, session:).call(params[:ticket])
    no_store
    render layout: false
  end
end
