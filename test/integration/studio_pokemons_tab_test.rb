# frozen_string_literal: true

require 'test_helper'

class StudioPokemonsTabTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'a trainer with no Pokémon sees empty party and challenge cards' do
    sign_in User.find(101) # users fixture user_101: no user_pokemons rows

    get tab_studio_path('pokemons'), as: :turbo_stream

    assert_includes response.body, I18n.t('pokemons.party.empty')
    assert_includes response.body, I18n.t('pokemons.opponent.no_party')
    assert_not_includes response.body, battle_start_path
  end

  test 'a trainer with Pokémon sees the party details and an opponent' do
    sign_in users(:user_one)

    get tab_studio_path('pokemons'), as: :turbo_stream

    assert_response :success
    assert_includes response.body, 'pokemon-details'
    assert_includes response.body, battle_start_path
  end
end
