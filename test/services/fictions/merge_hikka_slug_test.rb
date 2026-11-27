# frozen_string_literal: true

require 'test_helper'
require_relative 'merge_fixture'

module Fictions
  class MergeHikkaSlugTest < ActiveSupport::TestCase
    include MergeFixture

    setup do
      @admin = users(:user_one)
      @source = build_fiction('merge-source', 'Джерело')
      @target = build_fiction('merge-target', 'Ціль')
    end

    test 'moves the source Hikka title to a target that has none' do
      @source.update_column(:hikka_slug, 'guimi-zhi-zhu-7059fd')

      report = Merge.call(source: @source, target: @target, admin: @admin)

      assert_equal 'guimi-zhi-zhu-7059fd', @target.reload.hikka_slug
      assert_nil Fiction.with_deleted.find(@source.id).hikka_slug
      assert_includes report, 'hikka_slug moved guimi-zhi-zhu-7059fd'
    end

    test 'keeps the target Hikka title and drops the source one' do
      @source.update_column(:hikka_slug, 'guimi-zhi-zhu-7059fd')
      @target.update_column(:hikka_slug, 'monogatari-series-first-season-21fb1a')

      report = Merge.call(source: @source, target: @target, admin: @admin)

      assert_equal 'monogatari-series-first-season-21fb1a', @target.reload.hikka_slug
      assert_includes report, 'hikka_slug kept_target dropped guimi-zhi-zhu-7059fd'
    end

    test 'leaves the target alone and reports nothing when neither has a Hikka title' do
      report = Merge.call(source: @source, target: @target, admin: @admin)

      assert_nil @target.reload.hikka_slug
      assert_not_includes report, 'hikka_slug'
    end
  end
end
