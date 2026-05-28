# frozen_string_literal: true

require 'test_helper'

class BookshelvesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:user_one)
    @fiction = fictions(:one)
    @bookshelf = bookshelves(:one)
  end

  # Index action doesn't have a corresponding view, skipping this test

  test 'should show bookshelf' do
    get bookshelf_url(@bookshelf.sqid)

    assert_response :success
    assert_select 'h1', @bookshelf.title
  end

  test 'should get new when authenticated' do
    sign_in @user
    get new_bookshelf_url

    assert_response :success
  end

  test 'fiction_options returns json for authenticated user' do
    sign_in @user
    get fiction_options_bookshelves_url(q: @fiction.title.first(3), as: :json)

    assert_response :success
    body = response.parsed_body

    assert(body.any? { |option| option['value'] == @fiction.id.to_s })
  end

  test 'fiction_options requires authentication' do
    get fiction_options_bookshelves_url(q: 'test', as: :json)

    assert_redirected_to new_user_session_url
  end

  test 'should redirect to login when not authenticated for new' do
    get new_bookshelf_url

    assert_redirected_to new_user_session_url
  end

  test 'should create bookshelf when authenticated' do
    sign_in @user

    assert_difference('Bookshelf.count') do
      post bookshelves_url, params: {
        bookshelf: {
          title: 'New Bookshelf',
          description: 'New description',
          fiction_ids: [@fiction.id]
        }
      }
    end

    assert_redirected_to studio_index_path(tab: 'bookshelves')
    assert_equal 'Полицю дадано', flash[:notice]
  end

  test 'should not create bookshelf with invalid params' do
    sign_in @user

    assert_no_difference('Bookshelf.count') do
      post bookshelves_url, params: {
        bookshelf: {
          title: '', # Invalid - empty title
          description: 'New description'
        }
      }
    end

    assert_response :unprocessable_content
  end

  test 'should get edit when owner' do
    sign_in @user
    get edit_bookshelf_url(@bookshelf.sqid)

    assert_response :success
  end

  test 'should not get edit when not owner' do
    other_user = users(:user_two)
    sign_in other_user

    get edit_bookshelf_url(@bookshelf.sqid)

    assert_response :not_found
  end

  test 'should update bookshelf when owner' do
    sign_in @user

    patch bookshelf_url(@bookshelf.sqid), params: {
      bookshelf: {
        title: 'Updated Title',
        description: 'Updated description',
        fiction_ids: [@fiction.id] # Required by validation
      }
    }

    assert_redirected_to studio_index_path(tab: 'bookshelves')
    assert_equal 'Полицю оновлено!', flash[:notice]
    @bookshelf.reload

    assert_equal 'Updated Title', @bookshelf.title
  end

  test 'should not update bookshelf with invalid params' do
    sign_in @user

    patch bookshelf_url(@bookshelf.sqid), params: {
      bookshelf: {
        title: '' # Invalid - empty title
      }
    }

    assert_response :unprocessable_content
  end

  test 'should destroy bookshelf when owner' do
    sign_in @user

    assert_difference('Bookshelf.count', -1) do
      delete bookshelf_url(@bookshelf.sqid, format: :turbo_stream)
    end

    assert_response :success
  end
end
