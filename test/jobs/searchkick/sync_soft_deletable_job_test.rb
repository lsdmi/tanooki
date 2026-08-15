# frozen_string_literal: true

require 'test_helper'

module Searchkick
  class SyncSoftDeletableJobTest < ActiveSupport::TestCase
    test 'perform is a no-op outside production' do
      called = false
      sync = Object.new
      sync.define_singleton_method(:call) { called = true }

      SyncSoftDeletable.stub(:new, -> { sync }) do
        SyncSoftDeletableJob.new.perform
      end

      assert_not called
    end

    test 'perform runs search index sync in production' do
      called = false
      sync = Object.new
      sync.define_singleton_method(:call) { called = true }

      SyncSoftDeletable.stub(:new, -> { sync }) do
        Rails.stub(:env, ActiveSupport::StringInquirer.new('production')) do
          SyncSoftDeletableJob.new.perform
        end
      end

      assert called
    end
  end
end
