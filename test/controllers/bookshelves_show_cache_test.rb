# frozen_string_literal: true

require 'test_helper'

class BookshelvesShowCacheTest < ActionDispatch::IntegrationTest
  include QueryBudgetHelper

  setup do
    @bookshelf = bookshelves(:one)
    Rails.cache.clear
  end

  test 'show caches the fiction list fragment across requests' do
    cold = count_queries { get bookshelf_url(@bookshelf) }
    warm = count_queries { get bookshelf_url(@bookshelf) }

    assert_operator warm.size, :<, cold.size,
                    "warm #{warm.size} should be under cold #{cold.size}"
  end

  test 'fiction list cache busts when bookshelf membership is synced' do
    get bookshelf_url(@bookshelf)
    warm = count_queries { get bookshelf_url(@bookshelf) }

    Bookshelves::SyncFictions.call(
      bookshelf: @bookshelf,
      fiction_ids: @bookshelf.fictions.pluck(:id)
    )

    after_bust = count_queries { get bookshelf_url(@bookshelf) }

    assert_operator after_bust.size, :>, warm.size,
                    "after sync #{after_bust.size} should exceed warm #{warm.size}"
  end
end
