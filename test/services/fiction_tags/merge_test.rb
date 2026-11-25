# frozen_string_literal: true

require 'test_helper'

module FictionTags
  class MergeTest < ActiveSupport::TestCase
    setup do
      @source = fiction_tags(:litrpg)
      @target = fiction_tags(:rebirth)
      @one = fictions(:one)
      @two = fictions(:two)
    end

    test 'moves links to the target and deletes the source' do
      @one.fiction_tags << @source

      result = Merge.call(source: @source, target: @target)

      assert_equal [@target], @one.reload.fiction_tags.to_a
      assert_nil FictionTag.find_by(id: @source.id)
      assert_equal [1, 0], [result.moved, result.skipped]
    end

    test 'drops the source link when the fiction already has the target' do
      @one.fiction_tags << [@source, @target]
      @two.fiction_tags << @source

      result = Merge.call(source: @source, target: @target)

      carried = [@one, @two].map { |fiction| fiction.reload.fiction_tags.to_a }

      assert_equal [[@target], [@target]], carried
      assert_equal [1, 1], [result.moved, result.skipped]
    end

    test 'recounts the target' do
      @one.fiction_tags << [@source, @target]
      @two.fiction_tags << @source

      Merge.call(source: @source, target: @target)

      assert_equal 2, @target.reload.fictions_count
      assert_equal 2, FictionTagLink.where(fiction_tag: @target).count
    end

    test 'touches every fiction that carried the source and leaves the rest alone' do
      @one.fiction_tags << [@source, @target]
      @two.fiction_tags << @source
      untouched = fictions(:eighteen)
      untouched.fiction_tags << @target
      stamp = 1.day.ago
      [@one, @two, untouched].each do |fiction|
        fiction.updated_at = stamp
        fiction.save!(validate: false)
      end

      Merge.call(source: @source, target: @target)

      assert_operator @one.reload.updated_at, :>, stamp + 1.hour
      assert_operator @two.reload.updated_at, :>, stamp + 1.hour
      assert_in_delta stamp, untouched.reload.updated_at, 1
    end

    test 'an explicit source makes the target explicit' do
      @source.update!(explicit: true)
      @one.fiction_tags << @source

      Merge.call(source: @source, target: @target)

      assert_predicate @target.reload, :explicit?
    end

    test 'a non-explicit source leaves an explicit target alone' do
      @target.update!(explicit: true)

      Merge.call(source: @source, target: @target)

      assert_predicate @target.reload, :explicit?
    end

    test 'merging a tag without links just removes it' do
      Merge.call(source: @source, target: @target)

      assert_nil FictionTag.find_by(id: @source.id)
      assert_equal 0, @target.reload.fictions_count
    end

    test 'refuses to merge a tag into itself' do
      assert_raises(ArgumentError) { Merge.call(source: @target, target: @target) }
    end

    test 'refuses to merge into a hidden tag' do
      assert_raises(ArgumentError) { Merge.call(source: @source, target: fiction_tags(:yuri_hidden)) }
      assert_not_nil FictionTag.find_by(id: @source.id)
    end
  end
end
