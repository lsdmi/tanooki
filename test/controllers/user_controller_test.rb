# frozen_string_literal: true

require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @avatar_id = 1
    @user = users(:user_one)
  end

  test "should update user's avatar" do
    sign_in @user

    put :update_avatar, params: { id: @user.id, user: { avatar_id: @avatar_id } }

    @user.reload
    assert_equal @avatar_id, @user.avatar_id

    assert_response :redirect
    assert_equal 'Аватар оновлено.', flash[:notice]
  end
end
