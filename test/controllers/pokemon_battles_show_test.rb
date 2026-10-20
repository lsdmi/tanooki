# frozen_string_literal: true

require 'test_helper'

class PokemonBattlesShowTest < ActionDispatch::IntegrationTest
  include PokemonBattleHelpers

  setup do
    @attacker = users(:user_one)
    @defender = users(:user_two)
    team = [{ 'id' => 1, 'character' => 'brave', 'battle_experience' => 10, 'types' => %w[fire],
              'pokemon_id' => pokemons(:four).id, 'base_hp' => 100, 'base_attack' => 80 }]
    @battle = create_pokemon_battle(attacker: @attacker, defender: @defender, winner: @attacker,
                                    attacker_team: team,
                                    defender_team: [team.first.merge('id' => 2,
                                                                     'pokemon_id' => pokemons(:five).id)])
  end

  test 'guests can open a shareable battle page' do
    get pokemon_battle_path(@battle)

    assert_response :success
    assert_select 'h1', text: I18n.t('pokemons.battle.share_title', winner: @attacker.name, loser: @defender.name)
    assert_select '[data-controller="battle-replay"]'
  end

  test 'battle page sets Open Graph meta for sharing' do
    get pokemon_battle_path(@battle)

    assert_select "meta[property='og:image'][content=?]", pokemon_battle_og_url(@battle)
    assert_select "meta[property='og:title'][content=?]",
                  I18n.t('meta.title.pokemon_battles.show', winner: @attacker.name, loser: @defender.name)
  end

  test 'serves the Open Graph PNG' do
    get pokemon_battle_og_path(@battle)

    assert_response :success
    assert_equal 'image/png', response.media_type
    assert_operator response.body.bytesize, :>, 1_000
  end

  test 'unknown sqid is not found' do
    get pokemon_battle_path('missing')

    assert_response :not_found
  end
end
