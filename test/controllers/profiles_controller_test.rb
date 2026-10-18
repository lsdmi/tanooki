# frozen_string_literal: true

require 'test_helper'

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:user_one)
    @sqid = Sqids.new.encode([@user.id])
  end

  test 'should get show with valid user' do
    get "/profile/#{@sqid}"

    assert_response :success
    assert_equal @user, assigns(:user)
  end

  test 'should redirect to root with invalid user' do
    get '/profile/invalid_sqid'

    assert_response :redirect
    assert_redirected_to root_path
  end

  test 'show shells pokemon stats as a lazy turbo frame' do
    get profile_url(@sqid)

    assert_select 'turbo-frame#profile-pokemon-stats[src=?]', pokemon_stats_profile_path(@sqid)
    assert_nil assigns(:pokemon_count)
  end

  test 'pokemon_stats frame returns the dex card' do
    get pokemon_stats_profile_url(@sqid)

    assert_select 'turbo-frame#profile-pokemon-stats', text: /Покедекс/
    assert_not_nil assigns(:pokemon_count)
  end
end
