# frozen_string_literal: true

require 'test_helper'

module Fictions
  class RefreshDroppedStatusTest < ActiveSupport::TestCase
    setup do
      @fiction = fictions(:one)
      @fiction.update!(status: :ongoing)
      @fiction.chapters.destroy_all
      @fiction.chapters.create!(
        title: 'Stale chapter',
        number: 1,
        created_at: 100.days.ago,
        user: users(:user_one),
        content: 'a' * 500,
        scanlator_ids: [scanlators(:one).id]
      )
    end

    test 'call is a no-op outside production' do
      assert_no_changes -> { @fiction.reload.status } do
        RefreshDroppedStatus.call
      end
    end

    test 'call reports empty tallies outside production' do
      result = RefreshDroppedStatus.call

      assert_equal 0, result.scanned_ongoing
      assert_equal 0, result.dropped_ongoing
      assert_empty result.errors
    end

    test 'call marks inactive ongoing fictions as dropped in production' do
      Rails.stub(:env, ActiveSupport::StringInquirer.new('production')) do
        result = RefreshDroppedStatus.call

        assert_equal 'dropped', @fiction.reload.status
        assert_operator result.dropped_ongoing, :>=, 1
        assert_empty result.errors
      end
    end

    test 'call drops stale never-started announced fictions in production' do
      @fiction.update!(status: :announced, created_at: 100.days.ago)
      @fiction.chapters.destroy_all

      Rails.stub(:env, ActiveSupport::StringInquirer.new('production')) do
        result = RefreshDroppedStatus.call

        assert_equal 'dropped', @fiction.reload.status
        assert_operator result.dropped_announced, :>=, 1
        assert_empty result.errors
      end
    end

    test 'call skips finished fictions in production' do
      @fiction.update!(status: :finished)

      Rails.stub(:env, ActiveSupport::StringInquirer.new('production')) do
        assert_no_changes -> { @fiction.reload.status } do
          RefreshDroppedStatus.call
        end
      end
    end

    test 'call reports catalog totals after the pass' do
      Rails.stub(:env, ActiveSupport::StringInquirer.new('production')) do
        result = RefreshDroppedStatus.call

        assert_equal(
          [Fiction.ongoing.count, Fiction.announced.count, Fiction.dropped.count, Fiction.finished.count],
          [result.total_ongoing, result.total_announced, result.total_dropped, result.total_finished]
        )
      end
    end
  end
end
