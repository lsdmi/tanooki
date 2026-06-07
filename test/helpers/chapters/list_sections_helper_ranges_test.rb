# frozen_string_literal: true

require 'test_helper'

module Chapters
  class ListSectionsHelperRangesTest < ActionView::TestCase
    include ListSectionsHelper

    test 'chapter_list_sections uses range groups for unnumbered chapters' do
      fiction = fictions(:one)
      without_vol = create_range_chapter(fiction, number: 2, title: 'Plain chapter')

      sections = chapter_list_sections(fiction.chapters.where(id: without_vol.id))

      assert_equal 1, sections.size
      assert sections.first[:title].start_with?('Розділи ')
      assert_includes sections.first[:chapters], without_vol
    ensure
      without_vol&.destroy
    end

    test 'chapter_list_sections reverses chapter order within a range when desc' do
      fiction = fictions(:one)
      ch1, ch2 = create_range_chapter_pair(fiction)
      scope = fiction.chapters.where(id: [ch1.id, ch2.id])

      asc_ids = chapter_list_sections(scope, order: :asc).first[:chapters].pluck(:id)
      desc_ids = chapter_list_sections(scope, order: :desc).first[:chapters].pluck(:id)

      assert_equal [ch1.id, ch2.id], asc_ids
      assert_equal [ch2.id, ch1.id], desc_ids
    ensure
      ch2&.destroy
      ch1&.destroy
    end

    test 'chapter_list_sections uses only ranges when no volume numbers exist' do
      fiction = fictions(:one)
      chapter = create_range_chapter(fiction, number: 50, title: 'Range chapter')

      sections = chapter_list_sections(fiction.chapters.where(id: chapter.id))

      assert_equal 1, sections.size
      assert_equal 'Розділи 1-100', sections.first[:title]
    ensure
      chapter&.destroy
    end

    private

    def create_range_chapter_pair(fiction)
      [
        create_range_chapter(fiction, number: 1, title: 'Range low', content_letter: 'a'),
        create_range_chapter(fiction, number: 2, title: 'Range high', content_letter: 'b')
      ]
    end

    def create_range_chapter(fiction, number:, title:, content_letter: 'z')
      Chapter.create!(
        fiction: fiction,
        user: users(:user_one),
        title: title,
        number: number,
        volume_number: nil,
        content: content_letter * 500,
        scanlator_ids: [scanlators(:one).id]
      )
    end
  end
end
