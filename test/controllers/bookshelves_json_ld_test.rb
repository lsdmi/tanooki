# frozen_string_literal: true

require 'test_helper'

class BookshelvesJsonLdTest < ActionDispatch::IntegrationTest
  setup do
    @fiction = fictions(:one)
    @shelf = bookshelves(:one)
    pad_shelf!(@shelf)
  end

  test 'hub embeds CollectionPage ItemList and BreadcrumbList json-ld' do
    get bookshelves_url

    assert_response :success
    assert_match(/"@type":"CollectionPage".*"@type":"ItemList"/m, response.body)
    assert_match(/"@type":"BreadcrumbList"/, response.body)
  end

  test 'show embeds CollectionPage ItemList and BreadcrumbList json-ld for the shelf' do
    get bookshelf_url(@shelf.sqid)

    assert_response :success
    assert_match(/"@type":"CollectionPage"/, response.body)
    assert_match(/"@type":"BreadcrumbList".*#{Regexp.escape(@shelf.title)}/m, response.body)
  end

  private

  def pad_shelf!(shelf)
    while shelf.bookshelf_fictions.count < Bookshelves::HubScope::MIN_FICTIONS
      clone = @fiction.dup
      clone.title = "JSON-LD pad #{shelf.bookshelf_fictions.count}"
      clone.slug = nil
      clone.save!(validate: false)
      BookshelfFiction.create!(bookshelf: shelf, fiction: clone)
    end
  end
end
