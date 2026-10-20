# frozen_string_literal: true

require 'test_helper'

class UserPokemonsCatchJsonTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:user_one)
    @user.trainer_profile.update!(last_catch_at: 5.hours.ago)
    UserPokemon.where(user_id: [@user.id, users(:user_two).id], pokemon_id: pokemons(:four).id).destroy_all
    @encounter = PokemonEncounter.roll!(pokemon: pokemons(:four), user: @user)
    sign_in @user
  end

  test 'catching as JSON returns the decided result for the ring animation' do
    post catch_pokemon_path(format: :json), params: { encounter: @encounter.catch_token }

    assert_response :success
    assert response.parsed_body['caught']
    assert_equal I18n.t('pokemons.catch.success'), response.parsed_body['message']
  end

  test 'a rejected catch as JSON reports failure without catching' do
    assert_no_difference('UserPokemon.count') do
      post catch_pokemon_path(format: :json), params: { encounter: 'forged' }
    end
    assert_not response.parsed_body['caught']
    assert_equal I18n.t('pokemons.catch.failure'), response.parsed_body['message']
  end
end
