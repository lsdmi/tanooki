# frozen_string_literal: true

require 'test_helper'

module Users
  class RegistrationsControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers
    include WildEncounterHelpers

    def setup
      @user_params = {
        user: {
          avatar_id: 1,
          email: 'test@email.com',
          name: 'John Four',
          password: 'password',
          password_confirmation: 'password'
        }
      }
      ActionController::Base.cache_store.clear
    end

    test 'should show confirmation page' do
      get register_path

      assert_response :success
    end

    test 'should create a new user with valid sign-up parameters' do
      assert_difference 'User.count' do
        post register_path, params: @user_params
      end

      assert_redirected_to root_path
      assert_equal I18n.t('devise.registrations.signed_up_but_unconfirmed'), flash[:notice]
      verify_signup_user_matches_params
    end

    test 'should render the sign-up form with invalid parameters' do
      @user_params[:user][:name] = ''
      post register_path, params: @user_params

      assert_response :unprocessable_entity
      assert_template :new
      assert_equal 'Перевірте та виправте форму реєстрації:', flash[:alert]
    end

    test 'guest wild encounter transfers to the new account on sign up' do
      pokemon = pokemons(:two)

      with_guaranteed_encounter(pokemon) { get root_path }

      assert_equal [pokemon.id, nil], PokemonEncounter.last.values_at(:pokemon_id, :user_id)

      get register_path(pokenotice: true)

      assert_equal I18n.t('devise.registrations.pokemon_login_error'), flash[:notice]

      post register_path, params: @user_params

      assert_equal [pokemon.id], User.find_by(email: @user_params[:user][:email]).user_pokemons.pluck(:pokemon_id)
    end

    test 'pokenotice without a guest encounter shows no pokemon notice' do
      get register_path(pokenotice: true)

      assert_nil flash[:notice]
    end

    test 'rate limits sign up attempts per ip' do
      invalid_params = @user_params.deep_dup
      invalid_params[:user][:name] = ''

      5.times do
        post register_path, params: invalid_params, env: { 'REMOTE_ADDR' => '203.0.113.11' }

        assert_response :unprocessable_entity
      end

      post register_path, params: invalid_params, env: { 'REMOTE_ADDR' => '203.0.113.11' }

      assert_response :too_many_requests
    end

    private

    def verify_signup_user_matches_params
      last_user = User.last

      assert_equal @user_params[:user][:name], last_user.name
      assert_equal @user_params[:user][:avatar_id], last_user.avatar_id
      assert_equal @user_params[:user][:email], last_user.email
    end
  end
end
