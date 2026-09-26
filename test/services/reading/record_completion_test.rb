# frozen_string_literal: true

require 'test_helper'

module Reading
  class RecordCompletionTest < ActiveSupport::TestCase
    setup do
      @user = users(:user_one)
      @fiction = fictions(:one)
      @progress = reading_progresses(:one)
      @progress.update!(chapter: chapters(:one))
      ReadingChapterRead.where(user: @user).delete_all
      @chapters = (3..6).index_with { |number| create_chapter(number) }
    end

    test 'completing 3 then 6 stores only those two chapters' do
      complete(@chapters[3])
      complete(@chapters[6])

      assert_equal [@chapters[3].id, @chapters[6].id].sort, read_chapter_ids.sort
    end

    test 'completing 6 never inserts 4 or 5' do
      complete(@chapters[6])

      assert_empty read_chapter_ids & [@chapters[4].id, @chapters[5].id]
    end

    test 'second completion of the same chapter is a no-op' do
      assert complete(@chapters[6])

      assert_no_difference -> { ReadingChapterRead.count } do
        assert_not complete(@chapters[6])
      end
    end

    test 'stores source and completion time' do
      freeze_time do
        complete(@chapters[3], source: 'next')
        read = ReadingChapterRead.find_by!(user: @user, chapter: @chapters[3])

        assert_equal 'next', read.source
        assert_equal Time.current, read.completed_at
      end
    end

    test 'syncs completed_count with the read set' do
      complete(@chapters[3])
      complete(@chapters[6])
      complete(@chapters[6])

      assert_equal 2, @progress.reload.completed_count
    end

    test 'two translations of one chapter store both rows but count once' do
      other_team = create_chapter(3, scanlator: scanlators(:two))
      complete(@chapters[3])
      complete(other_team)

      assert_equal 2, read_chapter_ids.size
      assert_equal 1, @progress.reload.completed_count
    end

    test 'does not move the resume cursor' do
      complete(@chapters[6])

      assert_equal chapters(:one).id, @progress.reload.chapter_id
    end

    test 'completing the cursor chapter marks its stored position finished, keeping the quote' do
      @progress.update!(chapter: @chapters[3], resume_percent: 40, resume_quote: 'Тут')
      complete(@chapters[6])
      complete(@chapters[3], source: 'manual')

      assert_equal [100, 'Тут'], @progress.reload.values_at(:resume_percent, :resume_quote)
    end

    test 'a cursor chapter without a stored position stays without one' do
      complete(chapters(:one))

      assert_nil @progress.reload.resume_percent
    end

    test 'without a library row, the completed chapter becomes the resume point' do
      @progress.destroy!
      complete(@chapters[6])
      progress = ReadingProgress.find_by!(user: @user, fiction: @fiction)

      assert_equal @chapters[6].id, progress.chapter_id
      assert_equal 1, progress.completed_count
    end

    test 'new completion clears library and fiction caches' do
      keys = ["user:#{@user.id}:related_fictions:active", "fiction-#{@fiction.slug}-stats"]
      keys.each { |key| Rails.cache.write(key, 'stale') }
      complete(@chapters[3])

      assert(keys.all? { |key| Rails.cache.read(key).nil? })
    end

    test 'guest is a no-op' do
      assert_not RecordCompletion.new(chapter: @chapters[3], user: nil, source: 'scroll').call
    end

    private

    def complete(chapter, source: 'scroll')
      RecordCompletion.new(chapter:, user: @user, source:).call
    end

    def read_chapter_ids
      ReadingChapterRead.where(user: @user, fiction: @fiction).pluck(:chapter_id)
    end

    def create_chapter(number, scanlator: scanlators(:one))
      Chapter.create!(
        fiction: @fiction, user: @user, title: "Chapter #{number}", number:,
        content: 'x' * 500, scanlator_ids: [scanlator.id]
      )
    end
  end
end
