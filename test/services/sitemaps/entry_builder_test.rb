# frozen_string_literal: true

require 'test_helper'

module Sitemaps
  class EntryBuilderTest < ActiveSupport::TestCase
    test 'tale_entries omits drafts' do
      draft = publications(:tale_created_one)
      draft.update!(status: :draft)

      locs = EntryBuilder.new({ host: 'example.com' }).to_a.pluck(:loc)

      assert_not_includes locs, "http://example.com/tales/#{draft.slug}"
      assert_includes locs, "http://example.com/tales/#{publications(:tale_approved_one).slug}"
    end

    test 'a licensed work with hidden chapters keeps its fiction URL and lists no chapter URLs' do
      fiction = fictions(:one)
      fiction.scanlator_ids = fiction.scanlators.ids
      fiction.update!(licensed_at: 1.day.ago, license_publisher: 'Видавництво Тест', chapters_hidden_at: Time.current)

      locs = EntryBuilder.new({ host: 'example.com' }).to_a.pluck(:loc)

      assert_includes locs, "http://example.com/fictions/#{fiction.slug}"
      assert(locs.none? { |loc| loc.include?('/chapters/') })
    end

    test 'includes allowlisted archive shows without a contests index while unlisted' do
      locs = EntryBuilder.new({ host: 'example.com' }).to_a.pluck(:loc)

      assert_not_includes locs, 'http://example.com/contests'
      assert_includes locs, "http://example.com/contests/#{contests(:results).slug}"
      assert_not_includes locs, "http://example.com/contests/#{contests(:submissions).slug}"
    end

    test 'includes all visible contest shows and still omits the index when listed' do
      locs = listed_locs

      assert_not_includes locs, 'http://example.com/contests'
      assert_includes locs, "http://example.com/contests/#{contests(:submissions).slug}"
      assert_includes locs, "http://example.com/contests/#{contests(:results).slug}"
    end

    test 'omits draft contests when listed' do
      assert_not_includes listed_locs, "http://example.com/contests/#{contests(:draft).slug}"
    end

    test 'includes the bookshelves hub and sized public shelves' do
      shelf = sized_bookshelf!
      locs = EntryBuilder.new({ host: 'example.com' }).to_a.pluck(:loc)

      assert_includes locs, 'http://example.com/bookshelves'
      assert_includes locs, "http://example.com/bookshelves/#{shelf.sqid}"
    end

    test 'omits thin bookshelves from the sitemap' do
      thin = users(:user_one).bookshelves.create!(
        title: 'Thin sitemap shelf',
        description: 'Only two works so sitemap should omit this shelf',
        fiction_ids: [fictions(:one).id]
      )
      BookshelfFiction.where(bookshelf: thin).delete_all
      BookshelfFiction.create!(bookshelf: thin, fiction: fictions(:one))
      BookshelfFiction.create!(bookshelf: thin, fiction: fictions(:two))

      locs = EntryBuilder.new({ host: 'example.com' }).to_a.pluck(:loc)

      assert_not_includes locs, "http://example.com/bookshelves/#{thin.sqid}"
    end

    private

    def listed_locs
      Contests::PublicAccess.stub(:listed?, true) do
        EntryBuilder.new({ host: 'example.com' }).to_a.pluck(:loc)
      end
    end

    def sized_bookshelf!
      shelf = bookshelves(:one)
      while shelf.bookshelf_fictions.count < Bookshelves::HubScope::MIN_FICTIONS
        clone = fictions(:one).dup
        clone.title = "Sitemap pad #{shelf.bookshelf_fictions.count}"
        clone.slug = nil
        clone.save!(validate: false)
        BookshelfFiction.create!(bookshelf: shelf, fiction: clone)
      end
      shelf
    end
  end
end
