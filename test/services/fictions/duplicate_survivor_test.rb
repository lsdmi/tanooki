# frozen_string_literal: true

require 'test_helper'

module Fictions
  class DuplicateSurvivorTest < ActiveSupport::TestCase
    test 'keeps the page that is still publishing' do
      ongoing = fiction('survivor-live', chapter_count: 2, last_chapter_at: 1.day.ago)
      finished = fiction('survivor-done', chapter_count: 40, last_chapter_at: 1.day.ago, completed_at: Time.current)

      picked = DuplicateSurvivor.call([finished, ongoing], readers: { finished.id => 9, ongoing.id => 1 })

      assert_equal ongoing, picked
    end

    test 'keeps more chapters when none is still publishing' do
      short = fiction('survivor-short', chapter_count: 1, last_chapter_at: 1.year.ago, completed_at: Time.current)
      long = fiction('survivor-long', chapter_count: 9, last_chapter_at: 1.year.ago, completed_at: Time.current)

      picked = DuplicateSurvivor.call([short, long], readers: { short.id => 20, long.id => 1 })

      assert_equal long, picked
    end

    test 'keeps more bookmarks when the chapter counts match' do
      quiet = fiction('survivor-quiet', chapter_count: 4, last_chapter_at: 1.year.ago, completed_at: Time.current)
      popular = fiction('survivor-popular', chapter_count: 4, last_chapter_at: 1.year.ago, completed_at: 1.day.ago)

      picked = DuplicateSurvivor.call([quiet, popular], readers: { quiet.id => 1, popular.id => 8 })

      assert_equal popular, picked
    end

    private

    def fiction(slug, **attributes)
      record = Fiction.new(slug:, title: slug, author: 'Автор', description: 'd' * 30, **attributes)
      record.save!(validate: false)
      record
    end
  end
end
