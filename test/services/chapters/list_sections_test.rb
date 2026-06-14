# frozen_string_literal: true

require 'test_helper'

module Chapters
  class ListSectionsTest < ActiveSupport::TestCase
    test 'call groups chapters by volume' do
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

      sections = ListSections.new(fiction.chapters.where(id: with_vol.id)).call

      assert_equal 1, sections.size
      assert_equal 'Том 1', sections.first[:title]
      assert_includes sections.first[:chapters], with_vol
    ensure
      with_vol&.destroy
    end

    test 'call ignores inherited order when collecting volume numbers' do
      fiction = fictions(:one)
      ordered = fiction.chapters.order(number: :desc)

      assert_nothing_raised do
        ListSections.new(ordered, order: :desc).call
      end
    end

    test 'call reverses chapter order within a volume when desc' do
      fiction = fictions(:one)
      ch1 = create_volume_chapter(fiction, 1, 'First', number: 1)
      ch2 = create_volume_chapter(fiction, 1, 'Second', number: 2)
      scope = fiction.chapters.where(id: [ch1.id, ch2.id])

      asc_ids = ListSections.new(scope, order: :asc).call.first[:chapters].pluck(:id)
      desc_ids = ListSections.new(scope, order: :desc).call.first[:chapters].pluck(:id)

      assert_equal [ch1.id, ch2.id], asc_ids
      assert_equal [ch2.id, ch1.id], desc_ids
    ensure
      ch2&.destroy
      ch1&.destroy
    end

    test 'call reverses volume order when desc' do
      fiction = fictions(:one)
      vol1, vol2 = create_volume_pair_chapters(fiction)
      scope = fiction.chapters.where(id: [vol1.id, vol2.id])

      asc_titles = section_titles(ListSections.new(scope, order: :asc).call)
      desc_titles = section_titles(ListSections.new(scope, order: :desc).call)

      assert_equal ['Том 1', 'Том 2'], asc_titles
      assert_equal ['Том 2', 'Том 1'], desc_titles
    ensure
      vol2&.destroy
      vol1&.destroy
    end

    test 'call uses range groups for unnumbered chapters' do
      fiction = fictions(:one)
      without_vol = create_volume_chapter(fiction, nil, 'No vol', number: 5)

      sections = ListSections.new(fiction.chapters.where(id: without_vol.id)).call

      assert_equal 1, sections.size
      assert_equal :range, sections.first[:kind]
      assert_equal '1-100', sections.first[:range]
    ensure
      without_vol&.destroy
    end

    test 'call reverses chapter order within a range when desc' do
      fiction = fictions(:one)
      ch1 = create_volume_chapter(fiction, nil, 'A', number: 1)
      ch2 = create_volume_chapter(fiction, nil, 'B', number: 2)
      scope = fiction.chapters.where(id: [ch1.id, ch2.id])

      asc_ids = ListSections.new(scope, order: :asc).call.first[:chapters].pluck(:id)
      desc_ids = ListSections.new(scope, order: :desc).call.first[:chapters].pluck(:id)

      assert_equal [ch1.id, ch2.id], asc_ids
      assert_equal [ch2.id, ch1.id], desc_ids
    ensure
      ch2&.destroy
      ch1&.destroy
    end

    test 'call uses only ranges when no volume numbers exist' do
      fiction = fictions(:one)
      chapter = create_volume_chapter(fiction, nil, 'Only range', number: 3)

      sections = ListSections.new(fiction.chapters.where(id: chapter.id)).call

      assert_equal 1, sections.size
      assert_equal :range, sections.first[:kind]
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
