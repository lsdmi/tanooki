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
  end
end
