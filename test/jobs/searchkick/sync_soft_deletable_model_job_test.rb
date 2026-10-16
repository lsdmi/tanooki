# frozen_string_literal: true

require 'test_helper'

module Searchkick
  class SyncSoftDeletableModelJobTest < ActiveSupport::TestCase
    test 'perform is a no-op outside production' do
      synced = nil
      sync = Object.new
      sync.define_singleton_method(:sync_model) { |model| synced = model }

      SyncSoftDeletable.stub(:new, ->(**_) { sync }) do
        SyncSoftDeletableModelJob.new.perform('Fiction')
      end

      assert_nil synced
    end

    test 'perform syncs the named model with full_reindex in production' do
      synced = nil
      kwargs = nil
      sync = Object.new
      sync.define_singleton_method(:sync_model) { |model| synced = model }

      SyncSoftDeletable.stub(:new, lambda { |**options|
        kwargs = options
        sync
      }) do
        Rails.stub(:env, ActiveSupport::StringInquirer.new('production')) do
          SyncSoftDeletableModelJob.new.perform('Fiction')
        end
      end

      assert_equal({ full_reindex: true }, kwargs)
      assert_equal Fiction, synced
    end

    test 'perform rejects unknown model names' do
      Rails.stub(:env, ActiveSupport::StringInquirer.new('production')) do
        assert_raises(ArgumentError) { SyncSoftDeletableModelJob.new.perform('NotAModel') }
      end
    end
  end
end
