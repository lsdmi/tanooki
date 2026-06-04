# frozen_string_literal: true

require 'test_helper'

module Chapters
  class ListSectionsHelperTest < ActionView::TestCase
    include ListSectionsHelper

    test 'chapter_list_sections groups chapters by volume' do
      fiction = fictions(:one)
      with_vol = Chapter.create!(
        fiction: fiction,
        user: users(:user_one),
        title: 'Vol chapter',
        number: 1,
        volume_number: 1,
        content: 'x' * 500,
        scanlator_ids: [scanlators(:one).id]
      )

      sections = chapter_list_sections(fiction.chapters.where(id: with_vol.id))

      assert_equal 1, sections.size
      assert_equal 'Том 1', sections.first[:title]
      assert_includes sections.first[:chapters], with_vol
    ensure
      with_vol&.destroy
    end

    test 'chapter_list_sections uses range groups for unnumbered chapters' do
      fiction = fictions(:one)
      without_vol = Chapter.create!(
        fiction: fiction,
        user: users(:user_one),
        title: 'Plain chapter',
        number: 2,
        volume_number: nil,
        content: 'y' * 500,
        scanlator_ids: [scanlators(:one).id]
      )

      sections = chapter_list_sections(fiction.chapters.where(id: without_vol.id))

      assert_equal 1, sections.size
      assert sections.first[:title].start_with?('Розділи ')
      assert_includes sections.first[:chapters], without_vol
    ensure
      without_vol&.destroy
    end

    test 'chapter_list_sections ignores inherited order when collecting volume numbers' do
      fiction = fictions(:one)
      ordered = fiction.chapters.order(number: :desc)

      assert_nothing_raised do
        chapter_list_sections(ordered, order: :desc)
      end
    end

    test 'chapter_list_sections reverses chapter order within a volume when desc' do
      fiction = fictions(:one)
      ch1 = create_volume_chapter(fiction, 1, 'First', number: 1)
      ch2 = create_volume_chapter(fiction, 1, 'Second', number: 2)
      scope = fiction.chapters.where(id: [ch1.id, ch2.id])

      asc_ids = chapter_list_sections(scope, order: :asc).first[:chapters].pluck(:id)
      desc_ids = chapter_list_sections(scope, order: :desc).first[:chapters].pluck(:id)

      assert_equal [ch1.id, ch2.id], asc_ids
      assert_equal [ch2.id, ch1.id], desc_ids
    ensure
      ch2&.destroy
      ch1&.destroy
    end

    test 'chapter_list_sections reverses volume order when desc' do
      fiction = fictions(:one)
      vol1, vol2 = create_volume_pair_chapters(fiction)
      scope = fiction.chapters.where(id: [vol1.id, vol2.id])

      asc_titles = section_titles(chapter_list_sections(scope, order: :asc))
      desc_titles = section_titles(chapter_list_sections(scope, order: :desc))

      assert_equal ['Том 1', 'Том 2'], asc_titles
      assert_equal ['Том 2', 'Том 1'], desc_titles
    ensure
      vol2&.destroy
      vol1&.destroy
    end

    test 'chapter_list_sections reverses chapter order within a range when desc' do
      fiction = fictions(:one)
      ch1 = Chapter.create!(
        fiction: fiction,
        user: users(:user_one),
        title: 'Range low',
        number: 1,
        volume_number: nil,
        content: 'a' * 500,
        scanlator_ids: [scanlators(:one).id]
      )
      ch2 = Chapter.create!(
        fiction: fiction,
        user: users(:user_one),
        title: 'Range high',
        number: 2,
        volume_number: nil,
        content: 'b' * 500,
        scanlator_ids: [scanlators(:one).id]
      )
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
      chapter = Chapter.create!(
        fiction: fiction,
        user: users(:user_one),
        title: 'Range chapter',
        number: 50,
        volume_number: nil,
        content: 'z' * 500,
        scanlator_ids: [scanlators(:one).id]
      )

      sections = chapter_list_sections(fiction.chapters.where(id: chapter.id))

      assert_equal 1, sections.size
      assert_equal 'Розділи 1-100', sections.first[:title]
    ensure
      chapter&.destroy
    end

    private

    def section_titles(sections)
      sections.filter_map { |section| section[:title] }
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
  end
end
