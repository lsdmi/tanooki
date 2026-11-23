# frozen_string_literal: true

require 'test_helper'
require_relative 'merge_fixture'

module Fictions
  class MergeTagsTest < ActiveSupport::TestCase
    include MergeFixture

    setup do
      @shared = fiction_tags(:rebirth)
      @only = fiction_tags(:litrpg)
      @source = build_fiction('merge-source', 'Джерело')
      @target = build_fiction('merge-target', 'Ціль')
      FictionTagLink.create!(fiction: @target, fiction_tag: @shared)
      FictionTagLink.create!(fiction: @source, fiction_tag: @shared)
      FictionTagLink.create!(fiction: @source, fiction_tag: @only)
    end

    test 'unions tags without duplicating a shared tag' do
      Merge.call(source: @source, target: @target, admin: users(:user_one))

      assert_equal [@shared.id, @only.id].sort, FictionTagLink.where(fiction: @target).pluck(:fiction_tag_id).sort
      assert_empty FictionTagLink.where(fiction: @source)
    end

    test 'keeps tag counters equal to the live fictions carrying them' do
      Merge.call(source: @source, target: @target, admin: users(:user_one))

      assert_equal [1, 1], [@shared.reload.fictions_count, @only.reload.fictions_count]
    end
  end
end
