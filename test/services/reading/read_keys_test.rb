# frozen_string_literal: true

require 'test_helper'

module Reading
  class ReadKeysTest < ActiveSupport::TestCase
    setup do
      @user = users(:user_one)
      @fiction = fictions(:one)
      @progress = reading_progresses(:one)
      ReadingChapterRead.where(user: @user).delete_all
      @chapters = (3..6).index_with { |number| create_chapter(number) }
    end

    test 'without a legacy pointer only the sparse read set counts' do
      mark_read(@chapters[5])

      assert_equal Set[key(@chapters[5])], read_keys
    end

    test 'legacy pointer covers every listed chapter up to and including it' do
      @progress.update!(legacy_read_through_chapter_id: @chapters[4].id)

      assert_equal keys(chapters(:one), chapters(:two), @chapters[3], @chapters[4]), read_keys
    end

    test 'legacy pointer and sparse reads combine' do
      @progress.update!(legacy_read_through_chapter_id: @chapters[3].id)
      mark_read(@chapters[6])

      assert_equal keys(chapters(:one), chapters(:two), @chapters[3], @chapters[6]), read_keys
    end

    test 'a deleted legacy pointer chapter still marks its place' do
      @progress.update!(legacy_read_through_chapter_id: @chapters[4].id)
      create_chapter(4, scanlator: scanlators(:two))
      @chapters[4].destroy!

      assert_includes read_keys, key(@chapters[4])
    end

    test 'legacy pointer not in the listable chapters adds nothing' do
      draft = Chapter.create!(fiction: @fiction, user: @user, title: 'Draft', number: 7, status: :draft,
                              scanlator_ids: [scanlators(:one).id])
      @progress.update!(legacy_read_through_chapter_id: draft.id)

      assert_empty read_keys
    end

    test 'reads count without a library row' do
      mark_read(@chapters[3])

      assert_equal Set[key(@chapters[3])], ReadKeys.call(user: @user, fiction: @fiction, progress: nil)
    end

    private

    def read_keys = ReadKeys.call(user: @user, fiction: @fiction, progress: @progress.reload)

    def key(chapter) = ReadingChapterRead.chapter_key(chapter)

    def keys(*chapters) = chapters.to_set { |chapter| key(chapter) }

    def mark_read(chapter)
      ReadingChapterRead.create!(user: @user, fiction: @fiction, chapter:, completed_at: Time.current, source: 'scroll')
    end

    def create_chapter(number, scanlator: scanlators(:one))
      Chapter.create!(fiction: @fiction, user: @user, title: "Chapter #{number}", number:,
                      content: 'x' * 500, scanlator_ids: [scanlator.id])
    end
  end
end
