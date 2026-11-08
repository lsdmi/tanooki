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

    test 'includes allowlisted archive shows without the hub while unlisted' do
      locs = EntryBuilder.new({ host: 'example.com' }).to_a.pluck(:loc)

      assert_not_includes locs, 'http://example.com/contests'
      assert_includes locs, "http://example.com/contests/#{contests(:results).slug}"
      assert_not_includes locs, "http://example.com/contests/#{contests(:submissions).slug}"
    end

    test 'includes contests hub and visible contests when listed' do
      locs = listed_locs

      assert_includes locs, 'http://example.com/contests'
      assert_includes locs, "http://example.com/contests/#{contests(:submissions).slug}"
      assert_includes locs, "http://example.com/contests/#{contests(:results).slug}"
    end

    test 'omits draft contests when listed' do
      assert_not_includes listed_locs, "http://example.com/contests/#{contests(:draft).slug}"
    end

    private

    def listed_locs
      Contests::PublicAccess.stub(:listed?, true) do
        EntryBuilder.new({ host: 'example.com' }).to_a.pluck(:loc)
      end
    end
  end
end
