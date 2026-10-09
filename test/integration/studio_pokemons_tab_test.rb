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

  test 'a trainer in the top is marked on the board without a separate own row' do
    user = users(:user_one)
    user.trainer_profile.update!(last_battle_at: 1.day.ago)
    sign_in user

    get tab_studio_path('pokemons')

    assert_select '#pokemon-top-trainers li[aria-current=true]', count: 1
    assert_select '#pokemon-top-trainers li[aria-current=true] a', text: user.name
  end

  test 'a trainer outside the top sees their own place under it' do
    user = users(:user_one)
    [user, users(:user_two)].each { |trainer| trainer.trainer_profile.update!(last_battle_at: 1.day.ago) }
    place = Pokemons::DexLeaderboard.new.top_place_for(user)
    others = Pokemons::DexLeaderboard.new.top_rows.reject { |id, *| id == user.id }
    Rails.cache.write(Pokemons::DexLeaderboard::TOP_CACHE_KEY, others)
    sign_in user

    get tab_studio_path('pokemons')

    assert_select '#pokemon-top-trainers li[aria-current=true]', count: 1, text: /#{place}\s+#{user.name}/
  end

  test 'a trainer who has not battled lately is told how to get into the top' do
    users(:user_two).trainer_profile.update!(last_battle_at: 1.day.ago)
    sign_in users(:user_one)

    get tab_studio_path('pokemons')

    assert_select '#pokemon-top-trainers li[aria-current=true]', count: 0
    assert_select '#pokemon-top-trainers p', text: I18n.t('pokemons.top.join')
  end
end
