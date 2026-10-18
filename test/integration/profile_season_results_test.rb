# frozen_string_literal: true

require 'test_helper'

class ProfileSeasonResultsTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:user_one)
    @season = PokemonSeason.create!(number: 50, starts_on: Date.new(2026, 3, 1), ends_on: Date.new(2026, 4, 30),
                                    closed_at: Time.zone.parse('2026-05-01'))
    SeasonResult.create!(pokemon_season: @season, user: @user, place: 2, percentile: 0.8, glicko_rating: 1700,
                         glicko_deviation: 100, glicko_floor: 1500, battles: 5, wins: 3)
  end

  test 'a closed season shows a section on the profile pokemon stats frame' do
    get pokemon_stats_profile_path(@user.sqid)

    assert_response :success
    assert_select 'h3', text: I18n.t('pokemons.seasons.section')
  end

  test 'the season badge names the season and the place' do
    get pokemon_stats_profile_path(@user.sqid)

    assert_select 'li', text: /Сезон 50/
    assert_select 'li', text: /#2/
  end

  test 'a trainer with no closed seasons has no season section' do
    get pokemon_stats_profile_path(users(:user_two).sqid)

    assert_response :success
    assert_select 'h3', text: I18n.t('pokemons.seasons.section'), count: 0
  end
end
