# frozen_string_literal: true

require 'test_helper'

module Fictions
  class ChapterSectionLoaderTest < ActiveSupport::TestCase
    test 'parse_section_key for volume and range' do
      assert_equal({ kind: :volume, volume_number: '2' }, ChapterSectionLoader.parse_section_key('v-2'))
      assert_equal({ kind: :range, range: '1-100' }, ChapterSectionLoader.parse_section_key('r-1-100'))
    end

    test 'loads chapters for a volume section' do
      fiction = fictions(:one)
      chapter = Chapter.create!(
        fiction: fiction,
        user: users(:user_one),
        title: 'In volume',
        number: 3,
        volume_number: 2,
        content: 'x' * 500,
        scanlator_ids: [scanlators(:one).id]
      )

      loaded = ChapterSectionLoader.new(
        fiction: fiction,
        viewer: users(:user_one),
        section_key: 'v-2',
        order: :asc
      ).call

      assert_includes loaded, chapter
    ensure
      chapter&.destroy
    end

    test 'loads chapters for a numeric range section without chapter_ids' do
      fiction = fictions(:one)
      chapter = Chapter.create!(
        fiction: fiction,
        user: users(:user_one),
        title: 'In range',
        number: 205,
        volume_number: nil,
        content: 'x' * 500,
        scanlator_ids: [scanlators(:one).id]
      )

      loaded = ChapterSectionLoader.new(
        fiction: fiction,
        viewer: users(:user_one),
        section_key: 'r-201-300',
        order: :asc
      ).call

      assert_includes loaded, chapter
    ensure
      chapter&.destroy
    end

    test 'range sections hold the same chapters the section index puts in them' do
      fiction = fictions(:one)
      chapters = [0.5, 1, 100, 100.5, 101, 200.99].map do |number|
        Chapter.create!(fiction:, user: users(:user_one), title: "No. #{number}", number:, content: 'x' * 500,
                        scanlator_ids: [scanlators(:one).id])
      end

      %w[1-100 101-200].each do |range|
        loaded = ChapterSectionLoader.new(fiction:, viewer: users(:user_one), section_key: "r-#{range}",
                                          order: :asc).call
        expected = chapters.select { |chapter| Chapters::ListSectionIndex.range_label(chapter.number) == range }

        assert_equal expected.map(&:id).sort, (loaded.map(&:id) & chapters.map(&:id)).sort, range
      end
    ensure
      chapters&.each(&:destroy)
    end

    test 'loads chapters by chapter_ids when provided' do
      fiction = fictions(:one)
      chapter_ids = fiction.chapters.pluck(:id)

      loaded = ChapterSectionLoader.new(
        fiction: fiction,
        viewer: users(:user_one),
        section_key: 'r-1-100',
        order: :asc,
        chapter_ids: chapter_ids.join(',')
      ).call

      assert_equal chapter_ids.sort, loaded.pluck(:id).sort
    end
  end
end
