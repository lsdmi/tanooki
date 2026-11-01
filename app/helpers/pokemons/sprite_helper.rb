# frozen_string_literal: true

module Pokemons
  # Species sprites (animated GIFs) with their own width and height, so the slot keeps its size while the image loads.
  # Lazy unless the caller says otherwise. +shiny:+ adds the hue-shift filter and a sparkle frame around the image.
  module SpriteHelper
    def pokemon_sprite_tag(pokemon, alt: pokemon.name, shiny: false, **options)
      sprite = pokemon.sprite
      return unless sprite.attached?

      width, height = sprite.blob.metadata.values_at('width', 'height')
      classes = [options.delete(:class), ('pokemon-shiny' if shiny)].compact.join(' ').presence
      image = image_tag(url_for(sprite), alt:, width:, height:, loading: :lazy, decoding: :async,
                                         class: classes, **options)
      return image unless shiny

      tag.span(class: 'pokemon-shiny-sparkle inline-flex max-h-full max-w-full items-center justify-center') do
        image
      end
    end
  end
end
