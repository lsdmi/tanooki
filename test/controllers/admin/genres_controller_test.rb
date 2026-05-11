# frozen_string_literal: true

require 'test_helper'

module Admin
  class GenresControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    def setup
      @user = users(:user_one)
      sign_in @user
    end

    test 'should get index' do
      get admin_genres_url

      assert_response :success
      assert_genres_index_assigns
    end

    test 'should create genre' do
      assert_difference 'Genre.count' do
        post admin_genres_url, params: { genre: { name: 'New genre' } }
      end
      assert_response :success
      assert_genre_create_response('New genre')
    end

    test 'should not create invalid genre' do
      assert_no_difference 'Genre.count' do
        post admin_genres_url, params: { genre: { name: '' } }
      end
      assert_response :success
      assert_genre_invalid_create_response
    end

    test 'should destroy genre' do
      genre = genres(:one)
      assert_difference 'Genre.count', -1 do
        delete admin_genre_url(genre)
      end
      assert_response :success
      assert_genre_destroyed_response(genre)
    end

    test 'should edit genre' do
      genre = genres(:one)
      get edit_admin_genre_url(genre)

      assert_response :success
      assert_genre_edit_response(genre)
    end

    test 'should update genre' do
      genre = genres(:one)
      patch admin_genre_url(genre), params: { genre: { name: 'Updated genre' } }

      assert_response :success
      assert_genre_update_response('Updated genre')
    end

    test 'should not update genre with invalid attributes' do
      genre = genres(:one)
      patch admin_genre_url(genre), params: { genre: { name: '' } }

      assert_response :success
      assert_genre_invalid_update_response
    end

    private

    def assert_genres_index_assigns
      assert_template 'index'
      assert_not_nil assigns(:genres)
      assert_not_nil assigns(:genre)
    end

    def assert_genre_create_response(expected_name)
      assert_template 'admin/genres/_new'
      assert_template 'admin/genres/_genre'
      assert_not_nil assigns(:genre)
      assert_includes response.body, expected_name
    end

    def assert_genre_invalid_create_response
      assert_template 'admin/genres/_new'
      assert_not_nil assigns(:genre)
      assert_includes response.body, 'не може бути пустим'
    end

    def assert_genre_destroyed_response(genre)
      assert_template 'admin/genres/_genre'
      assert_template 'admin/genres/_list'
      assert_not Genre.exists?(genre.id)
      assert_not_includes response.body, ERB::Util.html_escape(genre.name)
    end

    def assert_genre_edit_response(genre)
      assert_template 'admin/genres/_edit'
      assert_not_nil assigns(:genre)
      assert_includes response.body, ERB::Util.html_escape(genre.name)
    end

    def assert_genre_update_response(expected_name)
      assert_template 'admin/genres/_genre'
      assert_template 'admin/genres/_list'
      assert_not_nil assigns(:genre)
      assert_equal expected_name, assigns(:genre).name
      assert_includes response.body, ERB::Util.html_escape(expected_name)
    end

    def assert_genre_invalid_update_response
      assert_template 'admin/genres/_edit'
      assert_not_nil assigns(:genre)
      assert_includes response.body, 'не може бути пустим'
    end
  end
end
