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

    test 'fiction_section_chapters matches the section query in both orders' do
      fiction = fictions(:one)

      %i[asc desc].each do |order|
        chapter_list_section_index(fiction, order:, viewer: nil).each do |section|
          expected = Fictions::ChapterSectionLoader.new(fiction:, viewer: nil, section_key: section[:section_key],
                                                        order:).call.map(&:id)

          assert_equal expected, fiction_section_chapters(fiction, section, order:, viewer: nil).map(&:id)
        end
      end
    end

    test 'fiction_section_chapters reuses the loaded list' do
      fiction = fictions(:one)
      section = chapter_list_section_index(fiction, order: :desc, viewer: nil).first

      assert_no_queries { fiction_section_chapters(fiction, section, order: :desc, viewer: nil, scanlators: false) }
    end

    test 'fiction_section_chapters preloads scanlators for the section only' do
      fiction = fictions(:one)
      section = chapter_list_section_index(fiction, order: :desc, viewer: nil).first
      chapters = fiction_section_chapters(fiction, section, order: :desc, viewer: nil)

      assert(chapters.all? { |chapter| chapter.association(:scanlators).loaded? })
    end

    test 'the first page grows in phone steps to reach the continue row' do
      sizes = [nil, 0, 19, 20, 39].map { |index| chapter_list_first_page_size(index) }

      assert_equal [20, 20, 20, 30, 40], sizes
    end

    test 'the open group is the continue chapter group, else the first one' do
      sections = [{ section_key: 'r-101-200' }, { section_key: 'r-1-100' }]

      assert_equal 'r-1-100', chapter_list_open_section_key(sections, chapters(:one))
      assert_equal 'r-101-200', chapter_list_open_section_key(sections, nil)
      assert_equal 'r-101-200', chapter_list_open_section_key(sections, Chapter.new(number: 1, volume_number: 3))
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
