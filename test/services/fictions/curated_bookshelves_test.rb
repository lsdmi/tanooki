# frozen_string_literal: true

require 'test_helper'

module Fictions
  class CuratedBookshelvesTest < ActiveSupport::TestCase
    setup do
      @fiction = fictions(:one)
      @low = bookshelves(:one)  # views: 0
      @high = bookshelves(:two) # views: 5
    end

    test 'returns bookshelves that include the fiction ordered by views' do
      BookshelfFiction.create!(bookshelf: @high, fiction: @fiction)

      result = CuratedBookshelves.call(fiction: @fiction)

      assert_equal [@high.id, @low.id], result.map(&:id)
    end

    test 'returns empty when the fiction is on no bookshelf' do
      assert_empty CuratedBookshelves.call(fiction: fictions(:eighteen))
    end

    test 'caps the list at LIMIT' do
      BookshelfFiction.where(fiction: @fiction).delete_all

      Fictions::CuratedBookshelves::LIMIT.succ.times do |i|
        shelf = Bookshelf.new(
          user: users(:user_one),
          title: "Shelf limit #{i} xx",
          description: 'Long enough description for the bookshelf validation.',
          views: i
        )
        shelf.fiction_ids = [@fiction.id]
        shelf.save!
        BookshelfFiction.create!(bookshelf: shelf, fiction: @fiction)
      end

      assert_equal Fictions::CuratedBookshelves::LIMIT, CuratedBookshelves.call(fiction: @fiction).size
    end
  end
end
