# frozen_string_literal: true

require 'test_helper'

module Admin
  class TagsControllerTest < ActionDispatch::IntegrationTest
    def setup
      @user = users(:user_one)
      sign_in @user
    end

    test 'should get index' do
      get admin_tags_url
      assert_response :success
      assert_template 'index'
      assert_not_nil assigns(:tags)
      assert_not_nil assigns(:tag)
    end

    test 'should create tag' do
      assert_difference 'Tag.count' do
        post admin_tags_url, params: { tag: { name: 'New Tag' } }
      end
      assert_response :success
      assert_template 'admin/tags/_new'
      assert_template 'admin/tags/_tag'
      assert_not_nil assigns(:tag)
      assert_includes response.body, 'New Tag'
    end

    test 'should not create invalid tag' do
      assert_no_difference 'Tag.count' do
        post admin_tags_url, params: { tag: { name: '' } }
      end
      assert_response :success
      assert_template 'admin/tags/_new'
      assert_not_nil assigns(:tag)
      assert_includes response.body, 'не може бути пустим'
    end

    test 'should destroy tag' do
      tag = tags(:one)
      assert_difference 'Tag.count', -1 do
        delete admin_tag_url(tag)
      end
      assert_response :success
      assert_template 'admin/tags/_tag'
      assert_template 'admin/tags/_list'
      assert_not Tag.exists?(tag.id)
      assert_not_includes response.body, tag.name
    end

    test 'should edit tag' do
      tag = tags(:one)
      get edit_admin_tag_url(tag)
      assert_response :success
      assert_template 'admin/tags/_edit'
      assert_not_nil assigns(:tag)
      assert_includes response.body, tag.name
    end

    test 'should update tag' do
      tag = tags(:one)
      patch admin_tag_url(tag), params: { tag: { name: 'Updated Tag' } }
      assert_response :success
      assert_template 'admin/tags/_tag'
      assert_template 'admin/tags/_list'
      assert_not_nil assigns(:tag)
      assert_equal 'Updated Tag', assigns(:tag).name
      assert_includes response.body, 'Updated Tag'
    end

    test 'should not update tag with invalid attributes' do
      tag = tags(:one)
      patch admin_tag_url(tag), params: { tag: { name: '' } }
      assert_response :success
      assert_template 'admin/tags/_edit'
      assert_not_nil assigns(:tag)
      assert_includes response.body, 'не може бути пустим'
    end
  end
end
