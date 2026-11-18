# frozen_string_literal: true

require 'test_helper'

class FictionOnBookshelvesTest < ActionDispatch::IntegrationTest
  setup do
    @fiction = fictions(:one)
    @bookshelf = bookshelves(:one)
    while @bookshelf.bookshelf_fictions.count < Fictions::CuratedBookshelves::MIN_FICTIONS
      clone = @fiction.dup
      clone.title = "About shelf pad #{@bookshelf.bookshelf_fictions.count}"
      clone.slug = nil
      clone.save!(validate: false)
      BookshelfFiction.create!(bookshelf: @bookshelf, fiction: clone)
    end
  end

  test 'about tab links to curated bookshelves that include the fiction' do
    get fiction_url(@fiction)

    assert_select '#fiction-on-bookshelves-title', text: 'На полицях'
    assert_select 'a[href=?]', bookshelves_path, text: I18n.t('fictions.about.on_bookshelves.all')
    assert_select 'ul li a[href=?]', bookshelf_path(@bookshelf), text: @bookshelf.title
  end

  test 'about tab omits on-bookshelves when the fiction is on none' do
    get fiction_url(fictions(:eighteen))

    assert_response :success
    assert_select '#fiction-on-bookshelves-title', count: 0
  end
end
