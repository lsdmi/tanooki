# frozen_string_literal: true

require 'test_helper'

class FictionsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @fiction = fictions(:one)
  end

  test 'should get show' do
    Rails.cache.delete("fiction_#{params[:id]}")
    get fiction_url(@fiction)
    assert_response :success
    assert_template :show
    assert_not_nil assigns(:fiction)
    assert_not_nil assigns(:commentable)
    assert_not_nil assigns(:comments)
    assert_not_nil assigns(:comment)
    assert_instance_of Comment, assigns(:comment)
  end

  private

  def params
    { id: @fiction.id }
  end
end
