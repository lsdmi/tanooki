# frozen_string_literal: true

require 'test_helper'

# The page view only rolls; the pop-up frame, loaded once the page is on screen, records the encounter.
class WildEncounterFlowTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include WildEncounterHelpers

  PREFETCH = { 'X-Sec-Purpose' => 'prefetch' }.freeze

  setup do
    sign_in users(:user_one)
    @pokemon = pokemons(:two)
  end

  test 'a hovered link that is never clicked writes nothing and the next visit can still roll' do
    with_winning_rolls do
      assert_no_difference('PokemonEncounter.count') { get root_path, headers: PREFETCH }
      assert_select 'turbo-frame#catch-pokemon[src]'

      get tales_path

      assert_select 'turbo-frame#catch-pokemon[src]'
    end
  end

  test 'a prefetched page records the encounter when it is shown' do
    with_winning_rolls do
      get root_path, headers: PREFETCH

      assert_difference('PokemonEncounter.count') { get css_select('turbo-frame#catch-pokemon').first['src'] }
      assert_select 'turbo-frame#catch-pokemon form[action=?]', catch_pokemon_path
    end
  end

  test 'the pop-up is named, labelled, and kept on screen' do
    with_guaranteed_encounter(@pokemon) { get root_path }

    assert_select 'turbo-frame#catch-pokemon div.absolute[data-turbo-temporary]' do
      assert_select 'button[aria-label=?]', "Спіймати #{@pokemon.name}"
      assert_select 'img[alt=?]', @pokemon.name
    end
  end

  test 'the guest pop-up opens sign-up outside the frame' do
    sign_out :user
    with_guaranteed_encounter(@pokemon) { get root_path }

    assert_select 'a[data-turbo-frame="_top"][aria-label=?]', "Спіймати #{@pokemon.name}"
  end

  test 'the frame without a ticket stays empty' do
    assert_no_difference('PokemonEncounter.count') { get wild_encounter_path }

    assert_select 'turbo-frame#catch-pokemon'
    assert_select 'turbo-frame#catch-pokemon *', count: 0
  end

  test 'the frame is not cached' do
    get wild_encounter_path

    assert_match 'no-store', response.headers['Cache-Control']
  end
end
