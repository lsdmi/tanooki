# frozen_string_literal: true

require 'test_helper'

module Bookshelves
  class SyncFictionsTest < ActiveSupport::TestCase
    setup do
      @bookshelf = bookshelves(:one)
      @fiction_one = fictions(:one)
      @fiction_two = fictions(:two)
    end

    test 'replaces bookshelf fictions in submitted order' do
      SyncFictions.call(bookshelf: @bookshelf, fiction_ids: [@fiction_two.id, @fiction_one.id])

      assert_equal [@fiction_two.id, @fiction_one.id],
                   @bookshelf.bookshelf_fictions.order(:id).pluck(:fiction_id)
    end

    test 'deduplicates fiction ids while preserving first occurrence order' do
      SyncFictions.call(
        bookshelf: @bookshelf,
        fiction_ids: [@fiction_two.id, @fiction_two.id, @fiction_one.id]
      )

      assert_equal [@fiction_two.id, @fiction_one.id],
                   @bookshelf.bookshelf_fictions.order(:id).pluck(:fiction_id)
      assert_equal 2, @bookshelf.bookshelf_fictions.count
    end

    test 'does nothing when fiction ids are blank' do
      assert_no_difference('@bookshelf.bookshelf_fictions.count') do
        SyncFictions.call(bookshelf: @bookshelf, fiction_ids: [])
      end

      assert_equal [@fiction_one.id, @fiction_two.id].sort, @bookshelf.fictions.pluck(:id).sort
    end
  end
end
