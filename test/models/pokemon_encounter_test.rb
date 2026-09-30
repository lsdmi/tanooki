# frozen_string_literal: true

require 'test_helper'

class PokemonEncounterTest < ActiveSupport::TestCase
  setup do
    @pokemon = pokemons(:one)
  end

  test 'roll! for a user opens an encounter that expires in 30 minutes' do
    freeze_time do
      encounter = PokemonEncounter.roll!(pokemon: @pokemon, user: users(:user_one))

      assert_predicate encounter, :open?
      assert_nil encounter.guest_token
      assert_equal 30.minutes.from_now, encounter.expires_at
    end
  end

  test 'roll! defaults to a non-shiny browse encounter' do
    encounter = PokemonEncounter.roll!(pokemon: @pokemon, user: users(:user_one))

    assert_equal ['browse', false], [encounter.source, encounter.shiny]
  end

  test 'roll! for a guest stores the guest token and no user' do
    encounter = PokemonEncounter.roll!(pokemon: @pokemon, guest_token: 'guest-token')

    assert_nil encounter.user_id
    assert_equal 'guest-token', encounter.guest_token
  end

  test 'requires exactly one owner' do
    neither = PokemonEncounter.new(pokemon: @pokemon, expires_at: 1.minute.from_now)
    both = PokemonEncounter.new(pokemon: @pokemon, user: users(:user_one), guest_token: 'guest-token',
                                expires_at: 1.minute.from_now)

    assert_not neither.valid?
    assert_not both.valid?
  end

  test 'rejects unknown sources and statuses' do
    encounter = PokemonEncounter.new(pokemon: @pokemon, user: users(:user_one), expires_at: 1.minute.from_now)

    encounter.source = 'shop'

    assert_not encounter.valid?

    encounter.source = 'reading'
    encounter.status = 'stolen'

    assert_not encounter.valid?
  end

  test 'claim! succeeds once' do
    encounter = PokemonEncounter.roll!(pokemon: @pokemon, user: users(:user_one))

    assert encounter.claim!
    assert_not encounter.claim!
    assert_predicate encounter.reload, :caught?
  end

  test 'claim! lets only one of two concurrent copies win' do
    first = PokemonEncounter.roll!(pokemon: @pokemon, user: users(:user_one))
    second = PokemonEncounter.find(first.id)

    assert_equal [true, false], [first.claim!, second.claim!]
  end

  test 'claim! rejects an expired encounter' do
    encounter = PokemonEncounter.roll!(pokemon: @pokemon, user: users(:user_one))

    travel PokemonEncounter::EXPIRES_IN + 1.second do
      assert_not encounter.claim!
    end
    assert_predicate encounter.reload, :open?
  end

  test 'catch token resolves only inside the owner scope' do
    encounter = PokemonEncounter.roll!(pokemon: @pokemon, user: users(:user_one))

    assert_equal encounter, users(:user_one).pokemon_encounters.for_catch_token(encounter.catch_token)
    assert_nil users(:user_two).pokemon_encounters.for_catch_token(encounter.catch_token)
    assert_nil PokemonEncounter.for_catch_token(encounter.id.to_s)
  end

  test 'deleting the user deletes their encounters' do
    user = users(:user_two)
    PokemonEncounter.roll!(pokemon: @pokemon, user:)

    assert_difference('PokemonEncounter.count', -1) { user.destroy }
  end
end
