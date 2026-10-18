# frozen_string_literal: true

require 'test_helper'

class PokemonTeamsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:user_one)
    @one = user_pokemons(:one)
    sign_in @user
  end

  test 'saves an ordered attack team' do
    extra = UserPokemon.create!(user: @user, pokemon: pokemons(:four), character: :brave, battle_experience: 1)

    patch pokemon_teams_path, params: { role: 'attack', user_pokemon_ids: [extra.id, @one.id] }, as: :turbo_stream

    assert_response :success
    assert_equal [extra.id, @one.id], @user.trainer_profile.reload.attack_team_ids
  end

  test 'saves a defense team separately' do
    patch pokemon_teams_path, params: { role: 'defense', user_pokemon_ids: [@one.id] }, as: :turbo_stream

    assert_equal [@one.id], @user.trainer_profile.reload.defense_team_ids
    assert_nil @user.trainer_profile.attack_team_ids
  end

  test 'rejects another trainer Pokémon' do
    patch pokemon_teams_path, params: { role: 'attack', user_pokemon_ids: [user_pokemons(:two).id] }, as: :turbo_stream

    assert_response :unprocessable_content
  end
end
