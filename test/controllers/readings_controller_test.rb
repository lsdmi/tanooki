# frozen_string_literal: true

require 'test_helper'

class ReadingsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:user_one) # assumes you have a users fixture
    @fiction = fictions(:one)    # assumes you have a fictions fixture
    @chapter = chapters(:one)    # assumes you have a chapters fixture
    sign_in @user                # Devise helper, or use your own
  end

  test 'should get show' do
    # Make sure @user is authorized for this fiction (admin or included)
    @user.fictions << @fiction unless @user.admin? || @user.fictions.include?(@fiction)
    get reading_url(@fiction)
    assert_response :success
  end

  test 'should destroy chapter' do
    # Make sure @user is authorized for this chapter (admin or included)
    @user.chapters << @chapter unless @user.admin? || @user.chapters.include?(@chapter)
    assert_difference('Chapter.count', -1) do
      delete reading_url(@chapter), as: :turbo_stream
    end
    assert_response :success
  end
end
