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

        model.search_index.stub(:exists?, true) do
          model.searchkick_index.stub(:remove, ->(removed_record) { removed << [model.name, removed_record] }) do
            model.stub(:reindex, -> { reindexed << model.name }) do
              model.stub(:only_deleted, soft_deleted_scope) do
                SyncSoftDeletable.new.send(:remove_soft_deleted, model)
                SyncSoftDeletable.new.send(:reindex, model)
              end
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

    test 'remove_soft_deleted skips cleanup when index is missing' do
      model = YoutubeVideo
      record = model.new(id: 1)
      soft_deleted_scope = Object.new
      soft_deleted_scope.define_singleton_method(:find_each) { |&block| block.call(record) }
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

    test 'remove_soft_deleted still reindexes when index is missing' do
      service = SyncSoftDeletable.new
      reindexed = []

      YoutubeVideo.search_index.stub(:exists?, false) do
        YoutubeVideo.stub(:reindex, -> { reindexed << YoutubeVideo.name }) do
          service.send(:remove_soft_deleted, YoutubeVideo)
          service.send(:reindex, YoutubeVideo)
        end
      end

      assert_equal [YoutubeVideo.name], reindexed
    end
  end
end
