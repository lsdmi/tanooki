# frozen_string_literal: true

require 'test_helper'

module Root
  class RecentlyUpdatedHelperTest < ActionView::TestCase
    include RecentlyUpdatedHelper

    test 'recently_updated_timestamp uses relative time' do
      travel_to Time.zone.parse('2026-07-13 12:00') do
        chapter = Struct.new(:public_at).new(2.hours.ago)

        assert_match(/годин.*тому\z/, recently_updated_timestamp(chapter))
      end
    end
  end
end
