# frozen_string_literal: true

require 'test_helper'

class FictionOnBookshelvesTest < ActionDispatch::IntegrationTest
  setup do
    @fiction = fictions(:one)
    @bookshelf = bookshelves(:one)
  end

  test 'about tab links to curated bookshelves that include the fiction' do
    get fiction_url(@fiction)

    assert_response :success
    assert_select '#fiction-on-bookshelves-title', text: 'На полицях'
    assert_select 'a[href=?]', bookshelf_path(@bookshelf), text: @bookshelf.title
  end

  test 'about tab omits on-bookshelves when the fiction is on none' do
    get fiction_url(fictions(:eighteen))

    assert_response :success
    assert_select '#fiction-on-bookshelves-title', count: 0
  end
end
