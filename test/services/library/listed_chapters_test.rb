# frozen_string_literal: true

require 'test_helper'

module Library
  class ListedChaptersTest < ActiveSupport::TestCase
    setup do
      RequestMemo.reset
      @fiction = fictions(:one)
      @chapter_one = chapters(:one)
      @chapter_two = chapters(:two)
    end

    test 'navigation, size and drawer share one chapter list load' do
      assert_queries_count(1) do
        ChapterNavigation.previous_chapter(@fiction, @chapter_two)
        ChapterNavigation.following_chapter(@fiction, @chapter_one)
        ChapterCatalog.chapters_size(@fiction)
        ChapterCatalog.listed_chapters(@fiction, order: :desc)
      end
    end

    test 'orders and viewers get their own lists' do
      admin = users(:user_one)

      assert_equal [@chapter_one, @chapter_two], ChapterCatalog.listed_chapters(@fiction, order: :asc)
      assert_equal [@chapter_two, @chapter_one], ChapterCatalog.listed_chapters(@fiction, order: :desc)
      assert_queries_count(1) { ChapterCatalog.listed_chapters(@fiction, viewer: admin) }
    end

    test 'a signed-in reader loads scanlator ids once' do
      viewer = users(:user_two)
      ChapterCatalog.chapters_scope_for_list(@fiction, viewer)

      assert_no_queries do
        ChapterCatalog.chapters_scope_for_list(@fiction, viewer)
        ChapterCatalog.guest_or_no_team_overlap?(@fiction, viewer)
      end
    end

    test 'scanlators are preloaded once for every listed chapter' do
      listed = ChapterCatalog.listed_chapters_with_scanlators(@fiction)

      assert_no_queries do
        ChapterCatalog.listed_chapters_with_scanlators(@fiction)
        listed.each { |chapter| chapter.scanlators.to_a }
      end
    end
  end
end
