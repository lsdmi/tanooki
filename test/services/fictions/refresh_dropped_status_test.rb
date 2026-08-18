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

      assert_equal 0, result.checked
      assert_equal 0, result.dropped
      assert_empty result.errors
    end

    test 'call marks inactive unfinished fictions as dropped in production' do
      Rails.stub(:env, ActiveSupport::StringInquirer.new('production')) do
        result = RefreshDroppedStatus.call

        assert_equal 'dropped', @fiction.reload.status
        assert_operator result.dropped, :>=, 1
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
  end
end
