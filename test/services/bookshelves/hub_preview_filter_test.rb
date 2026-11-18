# frozen_string_literal: true

require 'test_helper'

module Bookshelves
  class HubPreviewFilterTest < ActiveSupport::TestCase
    setup do
      @bookshelf = bookshelves(:two)
      @mild = fictions(:one)
      @hot = fictions(:eighteen)
      @filter = ContentFilters::Preference.new(max_rating: 16)
    end

    test 'decorate max content rating and count ignore filtered works' do
      replace_shelf!(@bookshelf, [@mild, @hot])

      entry = HubPreview.decorate([@bookshelf], include_covers: false, filter: @filter).first

      assert_equal Fiction.content_ratings.fetch('everyone'), entry.max_content_rating
      assert_equal 1, entry.fictions_count
    end

    test 'decorate top genres ignore filtered works' do
      genre_kept = genres(:one)
      genre_dropped = genres(:two)
      FictionGenre.where(fiction_id: [@mild.id, @hot.id]).delete_all
      FictionGenre.create!(fiction: @mild, genre: genre_kept)
      FictionGenre.create!(fiction: @hot, genre: genre_dropped)
      replace_shelf!(@bookshelf, [@mild, @hot])

      entry = HubPreview.decorate([@bookshelf], include_covers: false, filter: @filter).first

      assert_equal [genre_kept.name], entry.top_genres.map(&:name)
    end

    test 'decorate covers ignore filtered works' do
      replace_shelf!(@bookshelf, [@mild, @hot])
      ReadingProgress.where(fiction_id: [@mild.id, @hot.id]).delete_all

      entry = HubPreview.decorate([@bookshelf], filter: @filter).first

      assert_equal [@mild.id], entry.covers.map(&:id)
    end

    test 'decorate keeps full max content rating on the viewer own shelf' do
      bookshelf = bookshelves(:one)
      replace_shelf!(bookshelf, [@mild, @hot])

      entry = HubPreview.decorate([bookshelf], include_covers: false, viewer: bookshelf.user, filter: @filter).first

      assert_equal Fiction.content_ratings.fetch('eighteen'), entry.max_content_rating
    end

    private

    def replace_shelf!(bookshelf, fictions)
      BookshelfFiction.where(bookshelf:).delete_all
      fictions.each { |fiction| BookshelfFiction.create!(bookshelf:, fiction:) }
    end
  end
end
