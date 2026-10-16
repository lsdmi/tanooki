# frozen_string_literal: true

require 'test_helper'

module Searchkick
  class SyncSoftDeletableJobTest < ActiveSupport::TestCase
    test 'perform is a no-op outside production' do
      called = false
      sync = Object.new
      sync.define_singleton_method(:call) { called = true }

      SyncSoftDeletable.stub(:new, ->(**_) { sync }) do
        SyncSoftDeletableJob.new.perform
      end

      assert_not called
    end

    test 'perform runs cleanup sync in production' do
      called = false
      sync = Object.new
      sync.define_singleton_method(:call) { called = true }

      SyncSoftDeletable.stub(:new, lambda { |**kwargs|
        assert_equal({ full_reindex: false }, kwargs)
        sync
      }) do
        Rails.stub(:env, ActiveSupport::StringInquirer.new('production')) do
          SyncSoftDeletableJob.new.perform
        end
      end

      assert called
    end

    test 'perform with full_reindex enqueues one staggered model job per searchable model' do
      enqueued = []
      configured = Object.new
      configured.define_singleton_method(:perform_later) { |model_name| enqueued << model_name }

      SyncSoftDeletableModelJob.stub(:set, lambda { |wait:|
        enqueued << wait
        configured
      }) do
        Rails.stub(:env, ActiveSupport::StringInquirer.new('production')) do
          SyncSoftDeletableJob.new.perform('full_reindex')
        end
      end

      assert_equal [0.minutes, 'YoutubeVideo', 2.minutes, 'Publication', 4.minutes, 'Fiction'], enqueued
    end
  end
end
