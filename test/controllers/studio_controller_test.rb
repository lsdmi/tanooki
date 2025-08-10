# frozen_string_literal: true

require 'test_helper'

class StudioControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:user_one)
    sign_in(@user)
  end

  def test_index_requires_authentication
    sign_out
    get studio_index_path
    assert_redirected_to new_session_path
  end

  def test_index_with_authentication
    get studio_index_path
    assert_response :success
    assert_select 'section'
  end

  def test_tab_redirect
    get pokemons_path
    assert_redirected_to studio_index_path
  end
end
