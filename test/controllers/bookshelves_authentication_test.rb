# frozen_string_literal: true

require 'test_helper'

class BookshelvesAuthenticationTest < ActionDispatch::IntegrationTest
  setup do
    @bookshelf = bookshelves(:one)
  end

  test 'should redirect to login when creating without authentication' do
    post bookshelves_url, params: { bookshelf: { title: 'Test' } }

    assert_redirected_to new_user_session_url
  end

  test 'should redirect to login when editing without authentication' do
    get edit_bookshelf_url(@bookshelf.id)

    assert_redirected_to new_user_session_url
  end

  test 'should redirect to login when updating without authentication' do
    patch bookshelf_url(@bookshelf.id), params: { bookshelf: { title: 'Test' } }

    assert_redirected_to new_user_session_url
  end

  test 'should redirect to login when destroying without authentication' do
    delete bookshelf_url(@bookshelf.id)

    assert_redirected_to new_user_session_url
  end
end
