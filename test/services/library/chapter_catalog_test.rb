# frozen_string_literal: true

require 'test_helper'

module Library
  class ChapterCatalogTest < ActiveSupport::TestCase
    setup do
      @fiction = fictions(:one)
      @chapter_one = chapters(:one)
      @chapter_two = chapters(:two)
    end

    test 'ordered_chapters returns ordered chapters' do
      assert_equal [@chapter_one, @chapter_two], ChapterCatalog.ordered_chapters(@fiction).to_a
    end

    test 'chapters_size returns size of ordered chapters array' do
      assert_equal 2, ChapterCatalog.chapters_size(@fiction)
    end

    test 'ordered_chapters for guest excludes chapters not yet visible to everyone' do
      travel_to Time.zone.parse('2026-06-01 12:00') do
        update_chapter_schedule!(@chapter_one, published_at: 1.day.from_now)
        visible = ChapterCatalog.ordered_chapters(@fiction, viewer: nil).to_a

        assert_includes visible, @chapter_two
        assert_not_includes visible, @chapter_one
      ensure
        update_chapter_schedule!(@chapter_one, published_at: nil)
      end
    end

    test 'fiction_has_listable_chapters? is false when all chapters are future-published for guest' do
      travel_to Time.zone.parse('2026-06-01 12:00') do
        update_chapter_schedule!(@chapter_one, published_at: 1.day.from_now)
        update_chapter_schedule!(@chapter_two, published_at: 1.day.from_now)

        assert_not ChapterCatalog.fiction_has_listable_chapters?(@fiction, nil)
      ensure
        update_chapter_schedule!(@chapter_one, published_at: nil)
        update_chapter_schedule!(@chapter_two, published_at: nil)
      end
    end

    test 'ordered_chapters for guest excludes drafts' do
      mark_draft!(@chapter_one)
      visible = ChapterCatalog.ordered_chapters(@fiction, viewer: nil).to_a

      assert_includes visible, @chapter_two
      assert_not_includes visible, @chapter_one
    end

    test 'ordered_chapters for team excludes drafts from the public list' do
      teammate = team_member_on_fiction
      mark_draft!(@chapter_one)
      visible = ChapterCatalog.ordered_chapters(@fiction, viewer: teammate).to_a

      assert_includes visible, @chapter_two
      assert_not_includes visible, @chapter_one
    end

    test 'ordered_chapters for team includes scheduled published chapters' do
      travel_to Time.zone.parse('2026-06-01 12:00') do
        teammate = team_member_on_fiction
        update_chapter_schedule!(@chapter_one, published_at: 1.day.from_now)
        visible = ChapterCatalog.ordered_chapters(@fiction, viewer: teammate).to_a

        assert_includes visible, @chapter_one
        assert_includes visible, @chapter_two
      end
    end

    test 'ordered_chapters for admin excludes drafts' do
      mark_draft!(@chapter_one)
      visible = ChapterCatalog.ordered_chapters(@fiction, viewer: users(:user_one)).to_a

      assert_includes visible, @chapter_two
      assert_not_includes visible, @chapter_one
    end

    test 'ordered_user_chapters_desc includes drafts for the team' do
      teammate = team_member_on_fiction
      mark_draft!(@chapter_one)
      listed = ChapterCatalog.ordered_user_chapters_desc(@fiction, teammate).to_a

      assert_includes listed, @chapter_one
    end

    test 'ordered_user_chapters_desc sorts drafts ahead of published chapters' do
      mark_draft!(@chapter_one)
      listed = ChapterCatalog.ordered_user_chapters_desc(@fiction, users(:user_one)).to_a

      assert_equal @chapter_one, listed.first
      assert_includes listed, @chapter_two
    end

    private

    def team_member_on_fiction
      teammate = users(:user_two)
      ScanlatorUser.find_or_create_by!(user: teammate, scanlator: scanlators(:one))
      teammate.reload
    end

    def mark_draft!(chapter)
      chapter.update!(status: :draft, scanlator_ids: chapter.scanlators.ids)
    end

    def update_chapter_schedule!(chapter, published_at:)
      chapter.update!(published_at:, scanlator_ids: chapter.scanlators.ids)
    end
  end
end
