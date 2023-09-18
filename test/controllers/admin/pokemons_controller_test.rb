# frozen_string_literal: true

require 'test_helper'

class PokemonsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @pokemon = pokemons(:one)

    user = users(:user_one)
    sign_in user
    @pokemon_params = {
      sprite: Rack::Test::UploadedFile.new(
        Rails.root.join('app', 'assets', 'images', 'logo.svg'),
        'image/svg'
      ),
      name: 'Pikachu',
      power_level: @pokemon.power_level,
      rarity: @pokemon.rarity,
      ancestor_id: @pokemon.ancestor_id,
      descendant_id: 1,
      descendant_level: 0,
      dex_id: 1
    }
  end

  test 'should create pokemon' do
    assert_difference('Pokemon.count') do
      post admin_pokemons_url, params: { pokemon: @pokemon_params }
    end

    assert_redirected_to admin_pokemons_path
  end

  test 'should update pokemon' do
    patch admin_pokemon_url(@pokemon), params: { pokemon: @pokemon_params }
    assert_redirected_to admin_pokemons_path
  end

  test 'should destroy pokemon' do
    assert_difference('Pokemon.count', -1) do
      delete admin_pokemon_url(@pokemon)
    end

    assert_response :success
    assert_template 'admin/pokemons/_list'
  end

  test 'should get new' do
    get new_admin_pokemon_path
    assert_response :success
  end

  test 'should get edit' do
    get edit_admin_pokemon_path(Pokemon.first)
    assert_response :success
  end

  test 'pokemons should return all pokemons for admin users' do
    get admin_pokemons_path
    assert_response :success
  end
end
