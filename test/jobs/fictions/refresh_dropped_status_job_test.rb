# frozen_string_literal: true

require 'test_helper'

module Fictions
  class RefreshDroppedStatusJobTest < ActiveSupport::TestCase
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

    test 'perform is a no-op outside production' do
      assert_no_changes -> { @fiction.reload.status } do
        RefreshDroppedStatusJob.new.perform
      end
    end

    test 'perform marks inactive unfinished fictions as dropped in production' do
      Rails.stub(:env, ActiveSupport::StringInquirer.new('production')) do
        RefreshDroppedStatusJob.new.perform
      end

      assert_equal 'dropped', @fiction.reload.status
    end

    test 'perform skips finished fictions in production' do
      @fiction.update!(status: :finished)

      Rails.stub(:env, ActiveSupport::StringInquirer.new('production')) do
        assert_no_changes -> { @fiction.reload.status } do
          RefreshDroppedStatusJob.new.perform
        end
      end
    end
  end
end
