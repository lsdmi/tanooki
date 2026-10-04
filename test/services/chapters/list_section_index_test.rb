# frozen_string_literal: true

require 'test_helper'

module Chapters
  class ListSectionIndexTest < ActiveSupport::TestCase
    test 'volumes come first, then ranges of unnumbered chapters' do
      chapters = [chapter(1, number: 101), chapter(2, number: 5), chapter(3, number: 2, volume: 1)]

      sections = ListSectionIndex.new(chapters).call

      assert_equal %w[v-1.0 r-1-100 r-101-200], sections.pluck(:section_key)
      assert_equal ['Том 1 · Розділ 2', 'Розділ 5', 'Розділ 101'], sections.pluck(:title)
      assert_equal %i[volume range range], sections.pluck(:kind)
    end

    test 'range titles show the first and last chapter the group actually has' do
      chapters = [0.5, 100, 1901, 1999].each_with_index.map { |number, id| chapter(id, number:) }

      assert_equal ['Розділи 0.5–100', 'Розділи 1901–1999'], ListSectionIndex.new(chapters).call.pluck(:title)
    end

    test 'desc reverses section order but keeps chapter ids ascending' do
      chapters = [chapter(1, number: 2, volume: 1), chapter(2, number: 1, volume: 1), chapter(3, number: 1, volume: 2)]

      sections = ListSectionIndex.new(chapters, order: :desc).call

      assert_equal ['Том 2 · Розділ 1', 'Том 1 · Розділи 1–2'], sections.pluck(:title)
      assert_equal [2, 1], sections.last[:chapter_ids]
    end

    test 'volume EPUBs keep the bare volume title and keys count each chapter once' do
      chapters = [chapter(1, number: 1, volume: 1), chapter(2, number: 1, volume: 1), chapter(3, number: 2, volume: 1)]

      section = ListSectionIndex.new(chapters).call.first

      assert_equal 'Том 1', section[:epub_title]
      assert_equal 2, section[:chapter_keys].size
    end

    test 'chapters below 1 belong to the first range' do
      assert_equal '1-100', ListSectionIndex.range_label(BigDecimal('0.5'))
      assert_equal '1-100', ListSectionIndex.range_label(BigDecimal('100'))
      assert_equal '101-200', ListSectionIndex.range_label(BigDecimal('101'))
    end

    test 'a large volume keeps every chapter id' do
      chapters = (1..400).map { |n| chapter(100_000 + n, number: n, volume: 1) }

      assert_equal 400, ListSectionIndex.new(chapters).call.first[:chapter_ids].size
    end

    test 'groups loaded chapters without querying' do
      chapters = Library::ChapterCatalog.chapters_scope_for_list(fictions(:one), nil).to_a

      assert_no_queries { ListSectionIndex.new(chapters).call }
    end

    private

    def chapter(id, number:, volume: nil)
      Chapter.new(id:, number: BigDecimal(number.to_s), volume_number: volume && BigDecimal(volume.to_s))
    end
  end
end
