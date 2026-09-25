# frozen_string_literal: true

require 'test_helper'

class ReadingChapterReadTest < ActiveSupport::TestCase
  setup do
    @read = reading_chapter_reads(:one_fiction_one_chapter_two)
  end

  test 'fixture is valid' do
    assert_predicate @read, :valid?
  end

  test 'rejects unknown source' do
    @read.source = 'open'

    assert_not @read.valid?
    assert @read.errors.added?(:source, :inclusion, value: 'open')
  end

  test 'requires completed_at' do
    @read.completed_at = nil

    assert_not @read.valid?
  end

  test 'one read per user and chapter' do
    duplicate = @read.dup

    assert_not duplicate.valid?
    assert_raises(ActiveRecord::RecordNotUnique) { duplicate.save!(validate: false) }
  end

  test 'reading progress exposes reads for the same user and fiction only' do
    progress = reading_progresses(:one)
    other_fiction = ReadingChapterRead.create!(
      user: progress.user, fiction: fictions(:two), chapter: chapters(:three),
      completed_at: Time.current, source: 'next'
    )

    assert_equal [@read], progress.chapter_reads.to_a
    assert_not_includes progress.chapter_reads, other_fiction
  end

  test 'reads are not derived from the resume chapter' do
    progress = reading_progresses(:one)

    assert_not progress.chapter_reads.exists?(chapter_id: progress.chapter_id)
  end
end
