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
  end
end
