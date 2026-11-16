# frozen_string_literal: true

require 'test_helper'

class BookshelvesShowSurfaceTest < ActionDispatch::IntegrationTest
  setup do
    @bookshelf = bookshelves(:one)
  end

  test 'show drops the fiction picker' do
    get bookshelf_url(@bookshelf.sqid)

    assert_select '[data-controller="fiction-picker"]', count: 0
    assert_select '#fiction_details_frame', count: 0
  end

  test 'show has copy-link control' do
    get bookshelf_url(@bookshelf.sqid)

    assert_select '[data-controller="share-link"][data-share-link-url-value=?]', bookshelf_url(@bookshelf)
    assert_select '[data-action="share-link#copyUrl"][aria-label=?]', 'Скопіювати'
  end

  test 'show uses psyduck decoration background' do
    get bookshelf_url(@bookshelf.sqid)

    assert_select '[data-controller="lazy-bg"][data-lazy-bg-url-value]' do |nodes|
      assert_match(/psyduck_background/, nodes.first['data-lazy-bg-url-value'])
    end
  end

  test 'show links author to profile' do
    get bookshelf_url(@bookshelf.sqid)

    assert_select 'header a[href=?]', profile_path(@bookshelf.user_sqid)
  end
end
