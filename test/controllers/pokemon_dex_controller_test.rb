# frozen_string_literal: true

require 'test_helper'

class PokemonDexControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:user_one)
    sign_in @user
  end

  test 'show renders the dex for a signed-in trainer' do
    get pokemon_dex_path

    assert_response :success
    assert_select 'h1', text: 'Покедекс'
    assert_select 'ol[aria-label="Покедекс"] li', Pokemon.count
  end

  test 'turbo frame request returns only the dex panel' do
    get pokemon_dex_path, headers: { 'Turbo-Frame' => 'pokemon-dex' }

    assert_response :success
    assert_select 'turbo-frame#pokemon-dex'
    assert_select 'ol[aria-label="Покедекс"] li', Pokemon.count
  end

  test 'show filters by type inside the frame' do
    get pokemon_dex_path(type: 'normal'), headers: { 'Turbo-Frame' => 'pokemon-dex' }

    assert_response :success
    assert_select 'a[aria-current="true"][href=?]', pokemon_dex_path(type: 'normal')
    assert_select 'ol[aria-label="Покедекс"] li', 3
  end

  test 'guests are sent to login' do
    sign_out @user
    get pokemon_dex_path

    assert_redirected_to new_user_session_path
  end
end
