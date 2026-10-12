# frozen_string_literal: true

require 'test_helper'

class StudioPokemonsTabTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include PokemonBattleHelpers

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

  test 'the tab opens with the season line and the arena stage' do
    sign_in users(:user_one)

    get tab_studio_path('pokemons')

    assert_select 'h1', text: /Сезон/
    assert_select '[aria-label=Арена]'
  end

  test 'folded party is an overlapping dock and details keep a quiet stat line' do
    user = users(:user_one)
    strip = [user.user_pokemons.size, 5].min
    sign_in user

    get tab_studio_path('pokemons')

    assert_select '#pokemon-data-screen [data-panel-fold-target=closed] button', count: strip
    assert_select '#pokemon-details p[data-panel-fold-target=closed]', text: /витривалість/
  end

  test 'a trainer in the top is marked on the board without a separate own row' do
    user = users(:user_one)
    create_pokemon_battle(attacker: user, defender: users(:user_two))
    sign_in user

    get tab_studio_path('pokemons')

    assert_select '#pokemon-top-trainers li[aria-current=true]', count: 1
    assert_select '#pokemon-top-trainers li[aria-current=true] a', text: user.name
  end

  test 'a trainer outside the top sees their own place under it' do
    user = users(:user_one)
    create_pokemon_battle(attacker: user, defender: users(:user_two))
    place = Pokemons::DexLeaderboard.new.top_place_for(user)
    others = Pokemons::DexLeaderboard.new.top_rows.reject { |id, *| id == user.id }
    Rails.cache.write(Pokemons::DexLeaderboard.top_cache_key, others)
    sign_in user

    get tab_studio_path('pokemons')

    assert_select '#pokemon-top-trainers li[aria-current=true]', count: 1, text: /#{place}\s+#{user.name}/
  end

  test 'a trainer below the podium keeps their row in sight while the list is folded' do
    user = users(:user_one)
    ids = [*User.where.not(id: user.id).limit(4).pluck(:id), user.id]
    Rails.cache.write(Pokemons::DexLeaderboard.top_cache_key, ids.map.with_index(1) { |id, rank| [id, rank, 50] })
    row = /5\s+#{user.name}/
    sign_in user

    get tab_studio_path('pokemons')

    assert_select '#pokemon-top-trainers ol[hidden][data-panel-fold-target=open] li[aria-current=true]', text: row
    assert_select '#pokemon-top-trainers ol[data-panel-fold-target=closed] li[aria-current=true]', text: row
  end

  test 'a trainer who has not fought this season is told how to get into the top' do
    third = User.find(102)
    UserPokemon.create!(user: third, pokemon: pokemons(:one), character: :lucky, battle_experience: 1)
    create_pokemon_battle(attacker: users(:user_two), defender: third)
    sign_in users(:user_one)

    get tab_studio_path('pokemons')

    assert_select '#pokemon-top-trainers li[aria-current=true]', count: 0
    assert_select '#pokemon-top-trainers p', text: I18n.t('pokemons.top.join')
  end
end
