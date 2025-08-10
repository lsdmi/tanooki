# frozen_string_literal: true

require 'test_helper'

class ReadingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:user_one)
    @fiction = fictions(:one)
    @chapter = chapters(:one)
    sign_in @user
  end

  test 'should get show' do
    @user.fictions << @fiction unless @user.admin? || @user.fictions.include?(@fiction)
    get reading_url(@fiction)
    assert_response :success
  end

  test 'should destroy chapter' do
    assert @user.admin?, 'User should be admin'
    assert @user.scanlators.include?(@chapter.scanlators.first), "User should be associated with chapter's scanlator"

    assert_difference('Chapter.count', -1) do
      delete reading_url(@chapter), as: :turbo_stream
    end
    assert_response :success
  end

  teardown do
    sign_out
  end
end
