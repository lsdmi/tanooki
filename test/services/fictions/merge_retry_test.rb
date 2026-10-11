# frozen_string_literal: true

require 'test_helper'
require_relative 'merge_fixture'

module Fictions
  class MergeRetryTest < ActiveSupport::TestCase
    include MergeFixture

    setup do
      @admin = users(:user_one)
      @source = build_fiction('merge-source', 'Джерело')
      @target = build_fiction('merge-target', 'Ціль')
      @chapter = build_chapter(@source, 'merge-source-ch', 1)
    end

    test 'a second call reports that the fiction is already merged' do
      @source.views = 2
      @source.save!(validate: false)
      Merge.call(source: @source, target: @target, admin: @admin)

      report = Merge.call(source: Fiction.with_deleted.find(@source.id), target: @target.reload, admin: @admin)

      assert_equal 'already merged', report
      assert_equal 2, @target.reload.views
    end

    test 'a failed merge rolls back and the next call finishes' do
      merge = Merge.new(source: @source, target: @target, admin: @admin)
      def merge.retire_source
        raise 'boom'
      end

      assert_raises(RuntimeError) { merge.call }

      assert_equal @source.id, @chapter.reload.fiction_id
      Merge.call(source: @source.reload, target: @target.reload, admin: @admin)

      assert_equal @target.id, @chapter.reload.fiction_id
    end

    test 're-run after a failed publish does not double views' do
      @source.views = 4
      @source.save!(validate: false)
      merge = Merge.new(source: @source, target: @target, admin: @admin)
      def merge.publish!
        raise 'publish failed'
      end

      assert_raises(RuntimeError) { merge.call }

      Merge.call(source: Fiction.with_deleted.find(@source.id), target: @target.reload, admin: @admin)

      assert_equal 4, @target.reload.views
      assert_predicate Fiction.with_deleted.find(@source.id), :deleted?
    end

    test 'finishes a merge when chapters were already moved' do
      @chapter.fiction_id = @target.id
      @chapter.save!(validate: false)
      @source.views = 3
      @source.save!(validate: false)

      Merge.call(source: @source.reload, target: @target.reload, admin: @admin)

      assert_equal 1, Chapter.where(id: @chapter.id, fiction_id: @target.id).count
      assert_equal 3, @target.reload.views
      assert_predicate Fiction.with_deleted.find(@source.id), :deleted?
    end

    test 'requires an admin' do
      error = assert_raises(ArgumentError) do
        Merge.call(source: @source, target: @target, admin: users(:user_two))
      end

      assert_equal 'admin required', error.message
    end

    test 'refuses to merge a fiction into itself' do
      error = assert_raises(ArgumentError) do
        Merge.call(source: @source, target: @source, admin: @admin)
      end

      assert_equal 'source and target must differ', error.message
    end
  end
end
