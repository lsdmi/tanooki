# frozen_string_literal: true

require 'test_helper'

module Reading
  class MarkReadThroughTest < ActiveSupport::TestCase
    setup do
      @user = users(:user_one)
      @fiction = fictions(:one)
      @progress = reading_progresses(:one)
      @progress.update!(chapter: chapters(:one), resume_percent: nil)
      ReadingChapterRead.where(user: @user).delete_all
      @chapters = (3..5).index_with { |number| create_chapter(number) }
    end

    test 'reads every chapter from the first through the target' do
      result = mark_through(@chapters[4])

      assert_equal [chapters(:one), chapters(:two), @chapters[3], @chapters[4]].map(&:id), result.chapter_ids
      assert_equal result.chapter_ids.sort, read_chapter_ids.sort
      assert_equal %w[manual], ReadingChapterRead.where(user: @user).distinct.pluck(:source)
    end

    test 'skips chapters read already, so the result lists only what it added' do
      mark_read(chapters(:two))

      assert_equal [chapters(:one), @chapters[3]].map(&:id), mark_through(@chapters[3]).chapter_ids
      assert_equal 3, @progress.reload.completed_count
    end

    test 'a read of another translation counts as read' do
      mark_read(create_chapter(3, scanlator: scanlators(:two)))

      assert_not_includes mark_through(@chapters[3]).chapter_ids, @chapters[3].id
    end

    test 'nothing left to read adds nothing' do
      mark_read(chapters(:one), chapters(:two))

      assert_empty mark_through(chapters(:two)).chapter_ids
    end

    test 'marks the cursor position finished and returns the old one for the undo' do
      @progress.update!(resume_percent: 40)
      result = mark_through(@chapters[3])

      assert_equal 100, @progress.reload.resume_percent
      assert_equal 40, result.resume_percent
    end

    test 'starts a library row on the target when there is none' do
      @progress.destroy!
      mark_through(@chapters[3])

      assert_equal @chapters[3], ReadingProgress.find_by(user: @user, fiction: @fiction).chapter
    end

    test 'clears library and fiction caches' do
      Rails.cache.write(stats_key, 'stale')
      mark_through(@chapters[3])

      assert_nil Rails.cache.read(stats_key)
    end

    test 'undo removes only the reads the call added and restores the position' do
      mark_read(chapters(:two))
      @progress.update!(resume_percent: 40)
      result = mark_through(@chapters[4])
      undo(result)

      assert_equal [chapters(:two).id], read_chapter_ids
      assert_equal [40, 1], @progress.reload.values_at(:resume_percent, :completed_count)
    end

    test 'undo does not reorder the library' do
      result = mark_through(@chapters[3])

      assert_no_changes -> { @progress.reload.updated_at } do
        undo(result)
      end
    end

    private

    def mark_through(chapter) = MarkReadThrough.new(chapter:, user: @user).call

    def undo(result)
      UndoReadThrough.new(user: @user, fiction: @fiction, chapter_ids: result.chapter_ids,
                          resume_percent: result.resume_percent).call
    end

    def stats_key = "fiction-#{@fiction.slug}-stats"

    def read_chapter_ids
      ReadingChapterRead.where(user: @user, fiction: @fiction).pluck(:chapter_id)
    end

    def mark_read(*chapters)
      chapters.each do |chapter|
        ReadingChapterRead.create!(user: @user, fiction: @fiction, chapter:,
                                   completed_at: Time.current, source: 'scroll')
      end
    end

    def create_chapter(number, scanlator: scanlators(:one))
      Chapter.create!(fiction: @fiction, user: @user, title: "Chapter #{number}", number:,
                      content: 'x' * 500, scanlator_ids: [scanlator.id])
    end
  end
end
