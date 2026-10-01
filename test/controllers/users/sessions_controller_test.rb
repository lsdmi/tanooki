# frozen_string_literal: true

require 'test_helper'

module Users
  class SessionsControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers
    include WildEncounterHelpers

    setup do
      @user = users(:user_one)
      @user.update!(password: 'password', password_confirmation: 'password')
      ActionController::Base.cache_store.clear
    end

    test 'guest wild encounter transfers once on login' do
      pokemon = pokemons(:two)
      UserPokemon.where(user: @user, pokemon:).destroy_all

      with_guaranteed_encounter(pokemon) { get root_path }
      get register_path(pokenotice: true)
      post user_session_path, params: { user: { email: @user.email, password: 'password' } }

      assert_equal I18n.t('devise.sessions.signed_in_with_pokemon'), flash[:notice]
      assert UserPokemon.exists?(user: @user, pokemon:)
      assert_predicate PokemonEncounter.last, :caught?
    end

    test 'should create new user session without catch_pokemon' do
      post user_session_path, params: { user: { email: @user.email, password: 'password' } }

      assert_response :redirect
      assert_equal 1, UserPokemon.where(user_id: @user.id).count
    end

    test 'return_to on the sign-in page is where sign-in lands' do
      fiction_page = fiction_path(fictions(:one))
      get new_user_session_path(return_to: fiction_page)
      post user_session_path, params: { user: { email: @user.email, password: 'password' } }

      assert_redirected_to fiction_page
    end

    test 'return_to keeps only the path of an off-site url' do
      get new_user_session_path(return_to: 'https://evil.example/fictions/x')
      post user_session_path, params: { user: { email: @user.email, password: 'password' } }

      assert_redirected_to '/fictions/x'
    end

    test 'rate limits sign in attempts per ip' do
      5.times do
        post user_session_path,
             params: { user: { email: @user.email, password: 'wrong-password' } },
             env: { 'REMOTE_ADDR' => '203.0.113.10' }
      end

      post user_session_path,
           params: { user: { email: @user.email, password: 'wrong-password' } },
           env: { 'REMOTE_ADDR' => '203.0.113.10' }

      assert_response :too_many_requests
    end
  end
end

module Users
  class SessionsIntegrationTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      @user = users(:user_one)
      @controller = Users::SessionsController.new
      encounter = PokemonEncounter.roll!(pokemon: pokemons(:two), guest_token: 'guest-token')
      @session = { pokemon_guest_caught: true, pokemon_encounter_id: encounter.id, pokemon_guest_token: 'guest-token' }
    end

    test 'should create user pokemon and update turbo streams' do
      assert_difference('UserPokemon.count') do
        @controller.stub(:session, @session) do
          @controller.send(:catch_pokemon, @user)
        end
      end
    end
  end
end
