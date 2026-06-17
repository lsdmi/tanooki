# frozen_string_literal: true

require 'test_helper'

module Chapters
  class LinkFictionScanlatorsTest < ActiveSupport::TestCase
    test 'links persisted chapter teams to the fiction' do
      chapter = chapters(:one)
      fiction = chapter.fiction
      other_team = scanlators(:two)
      fiction.fiction_scanlators.where(scanlator: other_team).destroy_all
      ChapterScanlator.create!(chapter:, scanlator: other_team)

      LinkFictionScanlators.call(chapter:)

      assert FictionScanlator.exists?(fiction_id: fiction.id, scanlator_id: other_team.id)
    end

    test 'is idempotent when called more than once' do
      chapter = chapters(:one)
      fiction = chapter.fiction
      other_team = scanlators(:two)
      fiction.fiction_scanlators.where(scanlator: other_team).destroy_all
      ChapterScanlator.create!(chapter:, scanlator: other_team)

      assert_difference('FictionScanlator.count', 1) do
        LinkFictionScanlators.call(chapter:)
      end

      assert_no_difference('FictionScanlator.count') do
        LinkFictionScanlators.call(chapter:)
      end
    end

    test 'does nothing for an unpersisted chapter' do
      chapter = Chapter.new(
        scanlator_ids: [scanlators(:one).id],
        title: 'Draft',
        number: 99,
        content: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.' * 100,
        user: users(:user_one),
        fiction: fictions(:one)
      )

      assert_no_difference('FictionScanlator.count') do
        LinkFictionScanlators.call(chapter:)
      end
    end
  end
end
