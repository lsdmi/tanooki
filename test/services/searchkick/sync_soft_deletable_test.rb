# frozen_string_literal: true

require 'test_helper'

module Searchkick
  class SyncSoftDeletableTest < ActiveSupport::TestCase
    test 'removes soft-deleted records and reindexes each searchable model' do
      removed = []
      reindexed = []

      SyncSoftDeletable::MODELS.each do |model|
        record = model.new(id: 1)

        soft_deleted_scope = Object.new
        soft_deleted_scope.define_singleton_method(:find_each) { |&block| block.call(record) }

        model.searchkick_index.stub(:remove, ->(removed_record) { removed << [model.name, removed_record] }) do
          model.stub(:reindex, -> { reindexed << model.name }) do
            model.stub(:only_deleted, soft_deleted_scope) do
              SyncSoftDeletable.new.send(:remove_soft_deleted, model)
              SyncSoftDeletable.new.send(:reindex, model)
            end
          end
        end
      end

      assert_equal SyncSoftDeletable::MODELS.map(&:name), reindexed
      assert_equal SyncSoftDeletable::MODELS.size, removed.size
    end

    test 'call runs maintenance for every searchable model' do
      calls = 0
      service = SyncSoftDeletable.new

      service.stub(:remove_soft_deleted, ->(_model) { calls += 1 }) do
        service.stub(:reindex, ->(_model) { calls += 1 }) do
          service.call
        end
      end

      assert_equal SyncSoftDeletable::MODELS.size * 2, calls
    end
  end
end
