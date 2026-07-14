# frozen_string_literal: true

require 'test_helper'

module Fictions
  class LatestReleasedChaptersTest < ActiveSupport::TestCase
    test 'returns latest released chapter per fiction' do
      fiction = fictions(:one)
      older = chapters(:one)
      newer = chapters(:two)

      travel_to Time.zone.parse('2026-07-10 12:00') do
        older.update!(published_at: Time.current, scanlator_ids: older.scanlators.ids)
      end

      travel_to Time.zone.parse('2026-07-13 12:00') do
        newer.update!(published_at: Time.current, scanlator_ids: newer.scanlators.ids)
      end

      result = LatestReleasedChapters.for_fiction_ids([fiction.id])

      assert_equal newer, result[fiction.id]
    end

    test 'returns empty hash for blank ids' do
      assert_empty LatestReleasedChapters.for_fiction_ids([])
    end
  end
end
