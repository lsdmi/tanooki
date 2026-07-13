# frozen_string_literal: true

require 'test_helper'

module Fictions
  class LatestReleasedChaptersTest < ActiveSupport::TestCase
    test 'returns latest released chapter per fiction' do
      fiction = fictions(:one)
      older = chapters(:one)
      newer = chapters(:two)
      # rubocop:disable Rails/SkipsModelValidations -- ranking depends on historical publish timestamps
      older.update_columns(published_at: 2.days.ago, created_at: 2.days.ago)
      newer.update_columns(published_at: 1.hour.ago, created_at: 1.hour.ago, fiction_id: fiction.id)
      # rubocop:enable Rails/SkipsModelValidations

      result = LatestReleasedChapters.for_fiction_ids([fiction.id])

      assert_equal newer, result[fiction.id]
    end

    test 'returns empty hash for blank ids' do
      assert_empty LatestReleasedChapters.for_fiction_ids([])
    end
  end
end
