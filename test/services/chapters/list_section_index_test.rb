# frozen_string_literal: true

require 'test_helper'

module Chapters
  class ListSectionIndexTest < ActiveSupport::TestCase
    test 'call matches ListSections keys and chapter ids' do
      fiction = fictions(:one)
      scope = fiction.chapters

      assert_index_matches_sections(scope, order: :asc)
      assert_index_matches_sections(scope, order: :desc)
    end

    test 'call groups chapters by volume metadata' do
      fiction = fictions(:one)
      with_vol = create_volume_chapter(fiction, 1, 'Vol chapter', number: 1)
      scope = fiction.chapters.where(id: with_vol.id)
      section = ListSectionIndex.new(scope).call.first

      assert_equal 'Том 1', section[:title]
      assert_equal ListSections.volume_section_key(with_vol.volume_number), section[:section_key]
      assert_includes section[:chapter_ids], with_vol.id
    ensure
      with_vol&.destroy
    end

    test 'call uses range groups for unnumbered chapters' do
      fiction = fictions(:one)
      without_vol = create_volume_chapter(fiction, nil, 'No vol', number: 5)
      section = ListSectionIndex.new(fiction.chapters.where(id: without_vol.id)).call.first

      assert_equal :range, section[:kind]
      assert_equal 'r-1-100', section[:section_key]
    ensure
      without_vol&.destroy
    end

    test 'call respects visibility scope for guests' do
      fiction = fictions(:one)

      travel_to Time.zone.parse('2026-06-01 12:00') do
        chapter = chapters(:one)
        update_chapter_schedule!(chapter, published_at: 1.day.from_now)
        scope = Library::ChapterCatalog.chapters_scope_for_list(fiction, nil)
        chapter_ids = ListSectionIndex.new(scope).call.flat_map { |row| row[:chapter_ids] }

        assert_not_includes chapter_ids, chapter.id
        assert_includes chapter_ids, chapters(:two).id
      ensure
        update_chapter_schedule!(chapter, published_at: nil)
      end
    end

    test 'call reverses volume order when desc' do
      fiction = fictions(:one)
      vol1, vol2 = create_volume_pair_chapters(fiction)
      scope = fiction.chapters.where(id: [vol1.id, vol2.id])
      titles = ListSectionIndex.new(scope, order: :desc).call.pluck(:title)

      assert_equal ['Том 2', 'Том 1'], titles
    ensure
      vol2&.destroy
      vol1&.destroy
    end

    private

    def assert_index_matches_sections(scope, order:)
      index_sections = ListSectionIndex.new(scope, order: order).call
      full_sections = ListSections.new(scope, order: order).call

      assert_equal section_keys(full_sections), section_keys(index_sections)
      assert_matching_chapter_ids(full_sections, index_sections)
    end

    def section_keys(sections)
      sections.pluck(:section_key)
    end

    def assert_matching_chapter_ids(full_sections, index_sections)
      full_sections.zip(index_sections).each do |full, index|
        assert_equal full[:chapters].pluck(:id).sort, index[:chapter_ids].sort
      end
    end

    def create_volume_pair_chapters(fiction)
      [create_volume_chapter(fiction, 1, 'Vol 1'), create_volume_chapter(fiction, 2, 'Vol 2')]
    end

    def create_volume_chapter(fiction, volume_number, title, number: 1)
      Chapter.create!(
        fiction: fiction,
        user: users(:user_one),
        title: title,
        number: number,
        volume_number: volume_number,
        content: 'x' * 500,
        scanlator_ids: [scanlators(:one).id]
      )
    end

    def update_chapter_schedule!(chapter, published_at:)
      chapter.update!(published_at:, scanlator_ids: chapter.scanlators.ids)
    end
  end
end
