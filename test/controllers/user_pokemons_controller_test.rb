# frozen_string_literal: true

require 'test_helper'

class UserPokemonsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include WildEncounterHelpers

  setup do
    @pokemon_params = { user_pokemon_id: 1 }
    @user = users(:user_one)
    @user.trainer_profile.update!(last_catch_at: 5.hours.ago, last_training_at: 5.hours.ago)
    UserPokemon.where(user_id: [@user.id, users(:user_two).id], pokemon_id: pokemons(:four).id).destroy_all
    @encounter = PokemonEncounter.roll!(pokemon: pokemons(:four), user: @user)
    sign_in @user
  end

  test 'catching an open encounter adds its pokemon' do
    assert_difference('UserPokemon.count') { catch_with(@encounter.catch_token) }

    assert_includes response.body, I18n.t('pokemons.catch.success')
    assert UserPokemon.exists?(user: @user, pokemon: pokemons(:four))
  end

  test 'catching closes the encounter' do
    catch_with(@encounter.catch_token)

    assert_predicate @encounter.reload, :caught?
  end

  test 'the rendered pop-up posts a catch token that the endpoint accepts' do
    with_guaranteed_encounter(pokemons(:four)) { get root_path }
    token = css_select('turbo-frame#catch-pokemon form input[name="encounter"]').first&.[]('value')

    assert_predicate token, :present?
    assert_difference('UserPokemon.count') { catch_with(token) }
  end

  test 'a forged pokemon_id is ignored in favour of the encounter' do
    catch_with(@encounter.catch_token, user_pokemon: { pokemon_id: pokemons(:one).id })

    assert UserPokemon.exists?(user: @user, pokemon: pokemons(:four))
    assert_equal 1, user_pokemons(:one).reload.current_level
  end

  test 'a forged pokemon_id without an encounter catches nothing' do
    assert_rejected do
      post catch_pokemon_path(format: :turbo_stream), params: { user_pokemon: { pokemon_id: pokemons(:one).id } }
    end
    assert_equal 1, user_pokemons(:one).reload.current_level
  end

  test 'a raw encounter id is rejected' do
    assert_rejected { catch_with(@encounter.id.to_s) }
  end

  test 'an expired encounter is rejected' do
    travel PokemonEncounter::EXPIRES_IN + 1.minute do
      assert_rejected { catch_with(@encounter.catch_token) }
    end
  end

  test 'another user encounter is rejected and stays open' do
    foreign = PokemonEncounter.roll!(pokemon: pokemons(:four), user: users(:user_two))

    assert_rejected { catch_with(foreign.catch_token) }
    assert_predicate foreign.reload, :open?
  end

  test 'a caught encounter cannot be reused after the cooldown' do
    token = @encounter.catch_token
    catch_with(token)
    @user.trainer_profile.update!(last_catch_at: 5.hours.ago)

    assert_rejected { catch_with(token) }
  end

  test 'catching on cooldown keeps the encounter open' do
    @user.trainer_profile.update!(last_catch_at: 1.hour.ago)

    assert_rejected { catch_with(@encounter.catch_token) }
    assert_predicate @encounter.reload, :open?
  end

  test 'should ignore spoofed user id when catching pokemon' do
    other_user = users(:user_two)

    assert_difference -> { @user.user_pokemons.reload.count }, 1 do
      catch_with(@encounter.catch_token, user_id: other_user.id)
    end

    assert_not UserPokemon.exists?(user_id: other_user.id, pokemon_id: pokemons(:four).id)
  end

  test 'guest should not catch pokemon' do
    sign_out @user

    assert_no_difference('UserPokemon.count') { catch_with(@encounter.catch_token) }

    assert_redirected_to new_user_session_url
  end

  test 'training should refresh screen on success' do
    post training_pokemon_path(format: :turbo_stream), params: @pokemon_params

    assert_response :success
  end

  test 'training should refresh error screen on training fraud' do
    @user.trainer_profile.update!(last_training_at: Time.zone.now)
    post training_pokemon_path(format: :turbo_stream), params: @pokemon_params

    assert_response :success
  end

  test 'guest should not train pokemon' do
    sign_out @user

    post training_pokemon_path(format: :turbo_stream), params: @pokemon_params

    assert_redirected_to new_user_session_url
  end

  private

  def catch_with(token, **extra)
    post catch_pokemon_path(format: :turbo_stream), params: { encounter: token, **extra }
  end

  def assert_rejected(&)
    assert_no_difference('UserPokemon.count', &)
    assert_includes response.body, I18n.t('pokemons.catch.failure')
  end
end
