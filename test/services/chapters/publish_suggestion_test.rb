# frozen_string_literal: true

require 'test_helper'

module Chapters
  class PublishSuggestionTest < ActiveSupport::TestCase
    setup do
      @fiction = fictions(:one)
      @first = chapters(:one)
      @latest = chapters(:two)
    end

    test 'suggests the latest chapter publish moment when it is still ahead' do
      moment = 3.days.from_now.change(hour: 12, min: 0)
      schedule(@latest, moment)

      assert_equal moment.to_i, PublishSuggestion.call(@fiction).to_i
    end

    test 'suggests nothing when the latest chapter already went live' do
      # Scheduled while the clock read 3 days ago, so the moment is already past once the test runs.
      travel_to 3.days.ago do
        schedule(@latest, 2.days.from_now)
      end

      assert_nil PublishSuggestion.call(@fiction)
    end

    test 'suggests nothing for a live chapter without a schedule' do
      assert_nil PublishSuggestion.call(@fiction)
    end

    test 'ignores soft-deleted chapters' do
      moment = 2.days.from_now.change(hour: 9, min: 0)
      schedule(@first, moment)
      @latest.destroy

      assert_equal moment.to_i, PublishSuggestion.call(@fiction).to_i
    end

    test 'suggests nothing without a fiction' do
      assert_nil PublishSuggestion.call(nil)
    end

    private

    def schedule(chapter, moment)
      chapter.update!(published_at: moment, scanlator_ids: chapter.scanlators.ids)
    end
  end
end
