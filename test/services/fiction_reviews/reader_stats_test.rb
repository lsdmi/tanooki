# frozen_string_literal: true

require 'test_helper'

module FictionReviews
  class ReaderStatsTest < ActiveSupport::TestCase
    setup do
      @fiction = fictions(:one)
      @reader = users('user_101')
      FictionRating.create!(user: @reader, fiction: @fiction, rating: 4)
    end

    test 'the rating comes from the fiction the review is on' do
      stats = ReaderStats.new(fiction: @fiction, user_ids: [@reader.id])

      assert_equal 4, stats.rating_for(@reader.id)
    end

    test 'a reader with no rating of this fiction has no rating' do
      stats = ReaderStats.new(fiction: fictions(:two), user_ids: [@reader.id])

      assert_nil stats.rating_for(@reader.id)
    end

    test 'counts the chapters of this fiction the reader has read, whatever the source' do
      read(@reader, chapters(:one), 'manual')
      read(@reader, chapters(:two), 'scroll')

      assert_equal 2, ReaderStats.new(fiction: @fiction, user_ids: [@reader.id]).read_count_for(@reader.id)
    end

    test 'reads of another fiction do not count' do
      read(@reader, chapters(:three), 'manual')

      assert_equal 0, ReaderStats.new(fiction: @fiction, user_ids: [@reader.id]).read_count_for(@reader.id)
    end

    test 'a reader who read nothing has zero' do
      stats = ReaderStats.new(fiction: @fiction, user_ids: [users(:user_two).id])

      assert_equal 0, stats.read_count_for(users(:user_two).id)
    end

    test 'an empty batch does not ask the database' do
      stats = ReaderStats.new(fiction: @fiction, user_ids: [])

      assert_no_queries { stats.rating_for(1) && stats.read_count_for(1) }
    end

    test 'a batch of readers costs one query per figure, not one per reader' do
      other = users(:user_two) # rated fiction one in the fixtures
      stats = ReaderStats.new(fiction: @fiction, user_ids: [@reader.id, other.id, @reader.id])

      queries = count_queries { [stats.rating_for(@reader.id), stats.rating_for(other.id)] }

      assert_equal 1, queries
    end

    private

    def read(user, chapter, source)
      ReadingChapterRead.create!(user:, fiction: chapter.fiction, chapter:, completed_at: Time.current, source:)
    end

    def assert_no_queries(&)
      assert_equal 0, count_queries(&)
    end

    def count_queries(&)
      count = 0
      counter = lambda do |*, payload|
        count += 1 unless payload[:name] == 'SCHEMA' || payload[:cached]
      end
      ActiveSupport::Notifications.subscribed(counter, 'sql.active_record', &)
      count
    end
  end
end
