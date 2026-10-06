# frozen_string_literal: true

module Pokemons
  # Species sprites (animated GIFs) with their own width and height, so the slot keeps its size while the image loads.
  # Lazy unless the caller says otherwise.
  module SpriteHelper
    def pokemon_sprite_tag(pokemon, alt: pokemon.name, **)
      sprite = pokemon.sprite
      return unless sprite.attached?

      width, height = sprite.blob.metadata.values_at('width', 'height')
      image_tag(url_for(sprite), alt:, width:, height:, loading: :lazy, decoding: :async, **)
    end
  end
end
