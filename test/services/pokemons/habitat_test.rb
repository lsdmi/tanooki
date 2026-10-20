# frozen_string_literal: true

require 'test_helper'

module Pokemons
  class HabitatTest < ActiveSupport::TestCase
    setup { Habitat.reload! }

    test 'maps genre slugs to known type keys' do
      habitat = Habitat.new(genre_slugs: %w[fantasy horror])

      assert_equal %w[dragon ghost poison psychic], habitat.type_keys.sort
    end

    test 'accepts explicit pokemon type keys' do
      assert_equal %w[dragon], Habitat.new(type_keys: %w[dragon fairy]).type_keys
    end

    test 'drops types that are not in the type chart' do
      Habitat.stub(:config, { 'boost' => 4, 'genres' => { 'fantasy' => %w[dragon fairy] }, 'tags' => {} }) do
        assert_equal %w[dragon], Habitat.new(genre_slugs: %w[fantasy]).type_keys
      end
    end

    test 'builds from a genre record' do
      genre = Struct.new(:slug).new('fantasy')

      assert_equal %w[dragon psychic], Habitat.for(genre:).type_keys.sort
    end

    test 'builds from fiction genres' do
      fiction = Struct.new(:genres).new([Struct.new(:slug).new('horror')])

      assert_equal %w[ghost poison], Habitat.for(fiction:).type_keys.sort
    end

    test 'maps publication tags when configured' do
      Habitat.stub(:config, { 'boost' => 4, 'genres' => {}, 'tags' => { 'жахи' => %w[ghost] } }) do
        publication = Struct.new(:tags).new([Struct.new(:name).new('Жахи')])

        assert_equal %w[ghost], Habitat.for(publication:).type_keys
      end
    end

    test 'boost reads from yaml' do
      assert_equal 4, Habitat.boost
    end
  end
end
