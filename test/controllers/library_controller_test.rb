# frozen_string_literal: true

require 'test_helper'

class LibraryControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:user_two)
    sign_in @user
  end

  test 'should get index' do
    get library_url
    assert_response :success
  end

  test 'should fetch history with related associations' do
    get library_url
    assert_response :success

    assert_not_nil assigns(:history)
    assert_kind_of ActiveRecord::Relation, assigns(:history)

    assigns(:history).each do |reading|
      assert_not_nil reading.fiction
      assert_not_nil reading.chapter

      assert_not_nil reading.fiction.cover_attachment
      assert_not_nil reading.fiction.cover_attachment.blob

      assert_not_nil reading.fiction.genres
    end
  end
end
