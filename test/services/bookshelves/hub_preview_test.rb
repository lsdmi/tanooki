# frozen_string_literal: true

require 'test_helper'

module Bookshelves
  class HubPreviewTest < ActiveSupport::TestCase
    test 'popular returns at most four decorated shelves' do
      popular = HubPreview.popular
      # Touch includes(:user) so Bullet does not flag unused preload from the hub query.
      popular.each { |entry| entry.bookshelf.user }

      assert_operator popular.size, :<=, HubPreview::POPULAR_LIMIT
      assert_equal 4, HubPreview::POPULAR_LIMIT
    end

    test 'popular entries preload owner covers and genres' do
      entry = HubPreview.popular.first
      skip 'no popular shelves' unless entry

      assert_predicate entry.bookshelf.user, :present?
      assert_operator entry.covers.size, :<=, HubPreview::COVERS
      assert_operator entry.top_genres.size, :<=, HubPreview::TOP_GENRES
    end

    test 'recent scope excludes popular ids' do
      popular = HubPreview.popular
      popular.each { |entry| entry.bookshelf.user }
      popular_ids = popular.map { |entry| entry.bookshelf.id }
      recent = HubPreview.recent_scope(exclude_ids: popular_ids).limit(HubPreview::RECENT_PER_PAGE).to_a

      assert_empty recent.map(&:id) & popular_ids
    end

    test 'decorate without covers keeps owner and genres' do
      bookshelf = bookshelves(:one)
      entry = HubPreview.decorate([bookshelf], include_covers: false).first

      assert_predicate entry.bookshelf.user_name, :present?
      assert_empty entry.covers
      assert_operator entry.top_genres.size, :<=, HubPreview::TOP_GENRES
    end

    test 'decorate ranks top three genres by frequency on the shelf' do
      bookshelf = bookshelves(:one)
      fiction = fictions(:one)
      genre_a, genre_b, genre_c, genre_d = Genre.limit(4).to_a
      skip 'need four genres' if [genre_a, genre_b, genre_c, genre_d].any?(&:nil?)

      FictionGenre.where(fiction_id: fiction.id).delete_all
      [[genre_a, 3], [genre_b, 2], [genre_c, 1], [genre_d, 1]].each do |genre, copies|
        copies.times do |index|
          clone = fiction.dup
          clone.title = "Hub genre seed #{genre.id}-#{index}"
          clone.save!(validate: false)
          FictionGenre.create!(fiction: clone, genre:)
          BookshelfFiction.find_or_create_by!(bookshelf:, fiction: clone)
        end
      end

      entry = HubPreview.decorate([bookshelf]).first

      assert_equal [genre_a, genre_b, genre_c].map(&:name), entry.top_genres.map(&:name)
    end

    test 'decorate exposes max content rating on the shelf' do
      bookshelf = bookshelves(:one)
      mild = fictions(:one)
      hot = fictions(:two)
      mild.update!(content_rating: :everyone)
      hot.update!(content_rating: :eighteen)
      BookshelfFiction.where(bookshelf:).delete_all
      BookshelfFiction.create!(bookshelf:, fiction: mild)
      BookshelfFiction.create!(bookshelf:, fiction: hot)

      entry = HubPreview.decorate([bookshelf], include_covers: false).first

      assert_equal Fiction.content_ratings.fetch('eighteen'), entry.max_content_rating
    end

    test 'decorate ranks covers by bookmark count descending' do
      bookshelf = bookshelves(:one)
      low = fictions(:one)
      mid = fictions(:two)
      high = fictions(:eighteen)
      readers = User.order(:id).limit(3).to_a
      BookshelfFiction.where(bookshelf:).delete_all
      ReadingProgress.where(fiction_id: [low.id, mid.id, high.id]).delete_all

      assert([low, mid, high].all? { |fiction| fiction.cover.attached? })
      [low, mid, high].each { |fiction| BookshelfFiction.create!(bookshelf:, fiction:) }

      chapter_for = ->(fiction) { fiction.chapters.first || chapters(:one) }
      readers.first(1).each { |user| ReadingProgress.create!(user:, fiction: mid, chapter: chapter_for.call(mid)) }
      readers.first(3).each { |user| ReadingProgress.create!(user:, fiction: high, chapter: chapter_for.call(high)) }

      entry = HubPreview.decorate([bookshelf]).first

      assert_equal [high, mid, low].map(&:id), entry.covers.map(&:id)
    end
  end
end
