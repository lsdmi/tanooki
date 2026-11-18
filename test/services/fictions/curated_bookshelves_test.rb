# frozen_string_literal: true

require 'test_helper'

module Fictions
  class CuratedBookshelvesTest < ActiveSupport::TestCase
    setup do
      @fiction = fictions(:one)
      @low = bookshelves(:one)  # views: 0
      @high = bookshelves(:two) # views: 5
      pad_shelf!(@low, with: [@fiction, fictions(:two)])
      pad_shelf!(@high, with: [@fiction, fictions(:two)])
    end

    test 'returns bookshelves that include the fiction ordered by views' do
      result = CuratedBookshelves.call(fiction: @fiction)

      assert_equal [@high.id, @low.id], result.map(&:id)
    end

    test 'omits shelves below the minimum fiction count' do
      thin = users(:user_one).bookshelves.create!(
        title: 'Thin curated shelf',
        description: 'Only two works so fiction About should omit this shelf',
        fiction_ids: [@fiction.id]
      )
      BookshelfFiction.where(bookshelf: thin).delete_all
      BookshelfFiction.create!(bookshelf: thin, fiction: @fiction)
      BookshelfFiction.create!(bookshelf: thin, fiction: fictions(:two))

      result_ids = CuratedBookshelves.call(fiction: @fiction).map(&:id)

      assert_not_includes result_ids, thin.id
    end

    test 'omits foreign shelves the content filter would empty' do
      owner = users(:user_two)
      hot = fictions(:eighteen)
      shelf = owner.bookshelves.create!(
        title: 'Curated 18+ shelf xx',
        description: 'Only 18+ works so a capped reader should not see this shelf',
        fiction_ids: [@fiction.id],
        views: 50_000
      )
      BookshelfFiction.where(bookshelf: shelf).delete_all
      BookshelfFiction.create!(bookshelf: shelf, fiction: @fiction)
      while shelf.bookshelf_fictions.count < CuratedBookshelves::MIN_FICTIONS
        clone = hot.dup
        clone.title = "Curated hot pad #{shelf.bookshelf_fictions.count}"
        clone.slug = nil
        clone.content_rating = :eighteen
        clone.save!(validate: false)
        BookshelfFiction.create!(bookshelf: shelf, fiction: clone)
      end
      # Keep the current fiction on the shelf but make the rest 18+ only after filter
      # leaves fewer than MIN visible (everyone/16 rating for @fiction, 18 for pads).
      filter = ContentFilters::Preference.new(max_rating: 16)

      result_ids = CuratedBookshelves.call(fiction: @fiction, filter:).map(&:id)

      assert_not_includes result_ids, shelf.id
    end

    test 'keeps the viewer own shelf when the filter would empty it' do
      shelf = @low
      hot = fictions(:eighteen)
      BookshelfFiction.where(bookshelf: shelf).delete_all
      BookshelfFiction.create!(bookshelf: shelf, fiction: @fiction)
      while shelf.bookshelf_fictions.count < CuratedBookshelves::MIN_FICTIONS
        clone = hot.dup
        clone.title = "Own hot pad #{shelf.bookshelf_fictions.count}"
        clone.slug = nil
        clone.content_rating = :eighteen
        clone.save!(validate: false)
        BookshelfFiction.create!(bookshelf: shelf, fiction: clone)
      end
      filter = ContentFilters::Preference.new(max_rating: 16)

      result_ids = CuratedBookshelves.call(fiction: @fiction, viewer: shelf.user, filter:).map(&:id)

      assert_includes result_ids, shelf.id
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
        pad_shelf!(shelf, with: [@fiction, fictions(:two)])
      end

      assert_equal Fictions::CuratedBookshelves::LIMIT, CuratedBookshelves.call(fiction: @fiction).size
    end

    private

    def pad_shelf!(bookshelf, with:)
      BookshelfFiction.where(bookshelf:).delete_all
      with.each { |fiction| BookshelfFiction.create!(bookshelf:, fiction:) }
      while bookshelf.bookshelf_fictions.count < CuratedBookshelves::MIN_FICTIONS
        clone = with.first.dup
        clone.title = "Curated pad #{bookshelf.id}-#{bookshelf.bookshelf_fictions.count}"
        clone.slug = nil
        clone.save!(validate: false)
        BookshelfFiction.create!(bookshelf:, fiction: clone)
      end
    end
  end
end
