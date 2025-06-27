# frozen_string_literal: true

class PokemonDetailsService
  include ActionView::Helpers::TagHelper
  include ActionView::Context

  def initialize(pokemon_id)
    @pokemon_id = pokemon_id
  end

  def call
    ServiceResult.new(
      success: true,
      data: {
        selected_pokemon: selected_pokemon,
        descendant: descendant
      }
    )
  end

  private

  attr_reader :pokemon_id

  def selected_pokemon
    @selected_pokemon ||= UserPokemon.includes(:pokemon).find(pokemon_id)
  end

  def descendant
    return nil unless selected_pokemon.pokemon.descendant != selected_pokemon.pokemon

    @descendant ||= selected_pokemon.pokemon.descendant
  end

  def update_pokemon_details
    turbo_stream.replace(
      'pokemon-details',
      partial: 'users/pokemons/details',
      locals: { selected_pokemon: selected_pokemon, descendant: descendant }
    )
  end
end
