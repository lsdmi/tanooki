# frozen_string_literal: true

require 'test_helper'

module Chapters
  class ListSectionsHelperTest < ActionView::TestCase
    include ListSectionsHelper

    test 'chapter_list_sections delegates to ListSections service' do
      fiction = fictions(:one)
      chapters = fiction.chapters.where(id: chapters(:one).id)

      assert_equal ListSections.new(chapters).call, chapter_list_sections(chapters)
    end

    test 'fiction_chapter_section_path builds chapter section route' do
      fiction = fictions(:one)

      assert_equal chapter_section_fiction_path(fiction, section: 'v-1', order: :desc),
                   fiction_chapter_section_path(fiction, 'v-1', order: :desc)
    end

    test 'chapter_list_section_index delegates to ListSectionIndex' do
      fiction = fictions(:one)
      scope = Library::ChapterCatalog.chapters_scope_for_list(fiction, users(:user_one))

      assert_equal Chapters::ListSectionIndex.new(scope, order: :asc).call,
                   chapter_list_section_index(fiction, order: :asc, viewer: users(:user_one))
    end
  end
end
