# frozen_string_literal: true

require 'test_helper'

class BookmarksAccounterTest < ActiveSupport::TestCase
  setup do
    @fiction = fictions(:one)
    @chapter = chapters(:one)
  end

  test 'returns bookmark counts in status order' do
    ReadingProgress.create!(fiction: @fiction, user: users(:user_two), chapter: @chapter, status: :finished)
    ReadingProgress.create!(fiction: @fiction, user: User.find(101), chapter: @chapter, status: :postponed)

    result = BookmarksAccounter.new(fiction: @fiction).call

    assert_equal [1, 1, 1, 0], result
  end

  test 'uses one grouped count query' do
    grouped_queries = []
    subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
      sql = payload[:sql]
      grouped_queries << sql if sql.include?('reading_progresses') && sql.include?('GROUP BY')
    end

    BookmarksAccounter.new(fiction: @fiction).call

    assert_equal 1, grouped_queries.size
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end
end
