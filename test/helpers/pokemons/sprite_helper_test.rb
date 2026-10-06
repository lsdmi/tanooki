# frozen_string_literal: true

require 'test_helper'

module Pokemons
  class SpriteHelperTest < ActionView::TestCase
    include SpriteHelper

    setup do
      @pokemon = pokemons(:one)
      @pokemon.sprite.blob.update!(metadata: { 'width' => 96, 'height' => 80, 'analyzed' => true })
    end

    test 'pokemon_sprite_tag renders the lazy sprite at its size' do
      render html: pokemon_sprite_tag(@pokemon, class: 'size-9')

      assert_select 'img.size-9[loading=lazy][decoding=async][width="96"][height="80"]' do |images|
        assert_equal url_for(@pokemon.sprite), images.first['src']
        assert_equal @pokemon.name, images.first['alt']
      end
    end

    test 'pokemon_sprite_tag lets the caller load the sprite eagerly' do
      render html: pokemon_sprite_tag(@pokemon, alt: '', loading: :eager)

      assert_select 'img[loading=eager][alt=""]'
    end

    test 'pokemon_sprite_tag renders nothing without a sprite' do
      assert_nil pokemon_sprite_tag(Pokemon.new(name: 'Nobody'))
    end
  end
end
