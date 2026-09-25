# frozen_string_literal: true

require 'test_helper'

module Reading
  class RemoveReadTest < ActiveSupport::TestCase
    setup do
      @user = users(:user_one)
      @fiction = fictions(:one)
      @progress = reading_progresses(:one)
      @progress.update!(chapter: chapters(:one))
      ReadingChapterRead.where(user: @user).delete_all
      @chapters = (3..6).index_with { |number| create_chapter(number) }
    end

    test 'removes the read and syncs completed_count' do
      mark_read(@chapters[3], @chapters[6])

      assert remove(@chapters[6])
      assert_equal [@chapters[3].id], read_chapter_ids
      assert_equal 1, @progress.reload.completed_count
    end

    test 'removes reads of every translation of the chapter' do
      other_team = create_chapter(3, scanlator: scanlators(:two))
      mark_read(@chapters[3], other_team)
      remove(other_team)

      assert_empty read_chapter_ids
    end

    test 'removes a read of a since-deleted translation' do
      other_team = create_chapter(3, scanlator: scanlators(:two))
      mark_read(other_team)
      other_team.destroy!

      assert remove(@chapters[3])
      assert_empty read_chapter_ids
    end

    test 'unread of a chapter that was never read is a no-op' do
      Rails.cache.write(stats_key, 'keep')

      assert_not remove(@chapters[4])
      assert_equal 'keep', Rails.cache.read(stats_key)
    end

    test 'does not move the resume cursor or reorder the library' do
      mark_read(@chapters[6])
      @progress.update!(chapter: @chapters[6])

      assert_no_changes -> { @progress.reload.slice(:chapter_id, :updated_at) } do
        remove(@chapters[6])
      end
    end

    test 'clears library and fiction caches' do
      mark_read(@chapters[3])
      Rails.cache.write(stats_key, 'stale')
      remove(@chapters[3])

      assert_nil Rails.cache.read(stats_key)
    end

    test 'inside a legacy snapshot the rest of the range becomes real reads' do
      @progress.update!(legacy_read_through_chapter_id: @chapters[4].id)
      remove(@chapters[3])

      assert_equal [chapters(:one), chapters(:two), @chapters[4]].map(&:id).sort, read_chapter_ids.sort
      assert_equal %w[legacy], ReadingChapterRead.where(user: @user).distinct.pluck(:source)
    end

    test 'inside a legacy snapshot the snapshot is cleared' do
      @progress.update!(legacy_read_through_chapter_id: @chapters[4].id)
      remove(@chapters[3])

      assert_nil @progress.reload.legacy_read_through_chapter_id
      assert_equal 3, @progress.completed_count
    end

    test 'outside a legacy snapshot the snapshot stays' do
      @progress.update!(legacy_read_through_chapter_id: @chapters[3].id)
      mark_read(@chapters[6])
      remove(@chapters[6])

      assert_equal @chapters[3].id, @progress.reload.legacy_read_through_chapter_id
      assert_empty read_chapter_ids
    end

    test 'reads survive without a library row' do
      mark_read(@chapters[3])
      @progress.destroy!

      assert remove(@chapters[3])
      assert_empty read_chapter_ids
    end

    test 'guest is a no-op' do
      assert_not RemoveRead.new(chapter: @chapters[3], user: nil).call
    end

    private

    def remove(chapter) = RemoveRead.new(chapter:, user: @user).call

    def stats_key = "fiction-#{@fiction.slug}-stats"

    def read_chapter_ids
      ReadingChapterRead.where(user: @user, fiction: @fiction).pluck(:chapter_id)
    end

    def mark_read(*chapters)
      chapters.each do |chapter|
        ReadingChapterRead.create!(user: @user, fiction: @fiction, chapter:,
                                   completed_at: Time.current, source: 'manual')
      end
    end

    def create_chapter(number, scanlator: scanlators(:one))
      Chapter.create!(fiction: @fiction, user: @user, title: "Chapter #{number}", number:,
                      content: 'x' * 500, scanlator_ids: [scanlator.id])
    end
  end
end
