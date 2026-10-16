# frozen_string_literal: true

require 'test_helper'

module Searchkick
  class SyncSoftDeletableTest < ActiveSupport::TestCase
    test 'call without full_reindex only removes soft-deleted records' do
      removed_models = []
      reindexed = []
      service = SyncSoftDeletable.new(full_reindex: false)

      service.stub(:remove_soft_deleted, ->(model) { removed_models << model.name }) do
        service.stub(:reindex, ->(model) { reindexed << model.name }) do
          service.call
        end
      end

      assert_equal SyncSoftDeletable::MODELS.map(&:name), removed_models
      assert_empty reindexed
    end

    test 'call with full_reindex removes and reindexes each searchable model' do
      calls = []
      service = SyncSoftDeletable.new(full_reindex: true)

      service.stub(:remove_soft_deleted, ->(model) { calls << [:remove, model.name] }) do
        service.stub(:reindex, ->(model) { calls << [:reindex, model.name] }) do
          service.call
        end
      end

      SyncSoftDeletable::MODELS.each do |model|
        assert_includes calls, [:remove, model.name]
        assert_includes calls, [:reindex, model.name]
      end
    end

    test 'sync_model removes soft-deleted records and reindexes when full_reindex' do
      removed = []
      reindexed = []
      model = YoutubeVideo
      record = model.new(id: 1)

      soft_deleted_scope = Object.new
      soft_deleted_scope.define_singleton_method(:find_each) { |**_kwargs, &block| block.call(record) }

      model.search_index.stub(:exists?, true) do
        model.searchkick_index.stub(:remove, ->(removed_record) { removed << removed_record }) do
          model.stub(:reindex, -> { reindexed << model.name }) do
            model.stub(:only_deleted, soft_deleted_scope) do
              SyncSoftDeletable.new(full_reindex: true).sync_model(model)
            end
          end
        end
      end

      assert_equal [record], removed
      assert_equal [model.name], reindexed
    end

    test 'remove_soft_deleted skips cleanup when index is missing' do
      model = YoutubeVideo
      record = model.new(id: 1)
      soft_deleted_scope = Object.new
      soft_deleted_scope.define_singleton_method(:find_each) { |**_kwargs, &block| block.call(record) }
      removed = false

      model.search_index.stub(:exists?, false) do
        model.searchkick_index.stub(:remove, ->(*) { removed = true }) do
          model.stub(:only_deleted, soft_deleted_scope) do
            SyncSoftDeletable.new.send(:remove_soft_deleted, model)
          end
        end
      end

      assert_not removed
    end
  end
end
