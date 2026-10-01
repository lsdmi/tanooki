# frozen_string_literal: true

require 'test_helper'

module Chapters
  class ListSectionsHelperTest < ActionView::TestCase
    include ListSectionsHelper

    test 'fiction_chapter_section_path builds chapter section route' do
      fiction = fictions(:one)

      assert_equal chapter_section_fiction_path(fiction, section: 'v-1', order: :desc),
                   fiction_chapter_section_path(fiction, 'v-1', order: :desc)
    end

    test 'chapter_list_section_index groups the visible chapter list' do
      fiction = fictions(:one)
      listed = Library::ChapterCatalog.listed_chapters(fiction, viewer: users(:user_one))

      assert_equal Chapters::ListSectionIndex.new(listed, order: :asc).call,
                   chapter_list_section_index(fiction, order: :asc, viewer: users(:user_one))
    end

    test 'chapter_list_section_index hides chapters guests cannot see yet' do
      fiction = fictions(:one)

      travel_to Time.zone.parse('2026-06-01 12:00') do
        chapters(:one).update!(published_at: 1.day.from_now, scanlator_ids: chapters(:one).scanlators.ids)
        Library::RequestMemo.reset
        ids = chapter_list_section_index(fiction, order: :asc, viewer: nil).flat_map { |row| row[:chapter_ids] }

        assert_not_includes ids, chapters(:one).id
        assert_includes ids, chapters(:two).id
      end
    end
  end
end
