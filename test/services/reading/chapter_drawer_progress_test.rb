# frozen_string_literal: true

require 'test_helper'

module Reading
  class ChapterDrawerProgressTest < ActiveSupport::TestCase
    setup do
      @fiction = fictions(:one)
      @user = users(:user_one)
      @chapter_one = chapters(:one)
      @chapter_two = chapters(:two)
      ReadingChapterRead.where(user: @user).delete_all
    end

    test 'marks only chapters in the read set as read' do
      extra = (3..6).index_with { |number| create_chapter(number) }
      mark_read(extra[3], extra[6])
      progress = build(current_chapter: @chapter_one)

      statuses = extra.values.map { |chapter| progress.status_for(chapter) }

      assert_equal %i[read unread unread read], statuses
    end

    test 'reading one translation ticks the other translation of the same chapter' do
      other_team = create_chapter(2, scanlator: scanlators(:two))
      mark_read(@chapter_two)

      assert_equal :read, build(current_chapter: @chapter_one).status_for(other_team)
    end

    test 'same number in a different volume is a different chapter' do
      other_volume = create_chapter(2, volume_number: 2)
      mark_read(@chapter_two)

      assert_equal :unread, build(current_chapter: @chapter_one).status_for(other_volume)
    end

    test 'a deleted translation still ticks the surviving one' do
      survivor = create_chapter(2, scanlator: scanlators(:two))
      mark_read(@chapter_two)
      @chapter_two.destroy!

      assert_equal :read, build(current_chapter: @chapter_one).status_for(survivor)
    end

    test 'chapters before the resume chapter are not painted read' do
      reading_progresses(:one).update!(chapter: @chapter_two, status: :active)

      assert_equal :unread, build(current_chapter: nil).status_for(@chapter_one)
    end

    test 'pre-rebuild library row keeps ticks up to its old pointer' do
      reading_progresses(:one).update!(chapter: @chapter_two, legacy_read_through_chapter_id: @chapter_one.id)
      progress = build(current_chapter: nil)

      assert_equal %i[read unread], [progress.status_for(@chapter_one), progress.status_for(create_chapter(3))]
    end

    test 'resume chapter off screen is not current' do
      reading_progresses(:one).update!(chapter: @chapter_two, status: :active)

      assert_equal :unread, build(current_chapter: @chapter_one).status_for(@chapter_two)
    end

    test 'open chapter is current even when already read' do
      mark_read(@chapter_two)

      assert_equal :current, build(current_chapter: @chapter_two).status_for(@chapter_two)
    end

    test 'read? reports the open chapter even though its status is current' do
      mark_read(@chapter_two)

      assert build(current_chapter: @chapter_two).read?(@chapter_two)
    end

    test 'only signed-in readers of an unfinished fiction can toggle reads' do
      reader = build(current_chapter: nil)
      guest = ChapterDrawerProgress.build(fiction: @fiction, viewer: nil)
      reading_progresses(:one).update!(status: :finished)

      assert_equal [true, false, false], [reader, guest, build(current_chapter: nil)].map(&:toggleable?)
    end

    test 'marks all chapters read when fiction is finished' do
      reading_progresses(:one).update!(chapter: @chapter_one, status: :finished)
      progress = build(current_chapter: @chapter_two)

      assert_equal :current, progress.status_for(@chapter_two)
      assert_equal :read, progress.status_for(@chapter_one)
    end

    test 'marks other chapters unread without reading progress or reads' do
      ReadingProgress.where(fiction: @fiction, user: @user).delete_all
      progress = build(current_chapter: @chapter_two)

      assert_equal :unread, progress.status_for(@chapter_one)
      assert_equal :current, progress.status_for(@chapter_two)
    end

    test 'reads from another fiction do not leak in' do
      ReadingChapterRead.create!(user: @user, fiction: fictions(:two), chapter: chapters(:three),
                                 completed_at: Time.current, source: 'scroll')

      assert_equal :unread, build(current_chapter: nil).status_for(@chapter_one)
    end

    test 'guest sees only the open chapter as current' do
      mark_read(@chapter_one)
      progress = ChapterDrawerProgress.build(fiction: @fiction, viewer: nil, current_chapter: @chapter_two)

      assert_equal :unread, progress.status_for(@chapter_one)
      assert_equal :current, progress.status_for(@chapter_two)
    end

    test 'status lookups do not query' do
      mark_read(@chapter_one)
      progress = build(current_chapter: @chapter_two)

      assert_no_queries do
        progress.status_for(@chapter_one)
        progress.status_for(@chapter_two)
      end
    end

    private

    def build(current_chapter:) = ChapterDrawerProgress.build(fiction: @fiction, viewer: @user, current_chapter:)

    def mark_read(*chapters)
      chapters.each do |chapter|
        ReadingChapterRead.create!(user: @user, fiction: chapter.fiction, chapter:,
                                   completed_at: Time.current, source: 'scroll')
      end
    end

    def create_chapter(number, volume_number: nil, scanlator: scanlators(:one))
      Chapter.create!(fiction: @fiction, user: @user, title: "Chapter #{number}", number:, volume_number:,
                      content: 'x' * 500, scanlator_ids: [scanlator.id])
    end
  end
end
