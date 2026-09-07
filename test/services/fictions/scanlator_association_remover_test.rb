# frozen_string_literal: true

require 'test_helper'

module Fictions
  class ScanlatorAssociationRemoverTest < ActiveSupport::TestCase
    test 'removes scanlator chapters and fiction link' do
      fiction = fictions(:one)
      scanlator = scanlators(:one)

      assert_difference -> { scanlator_chapter_count(fiction, scanlator) }, -2 do
        ScanlatorAssociationRemover.new(fiction, scanlator).call
      end

      assert_not FictionScanlator.exists?(fiction:, scanlator:)
    end

    test 'refreshes chapter_count after removing the team chapters' do
      fiction = fictions(:one)
      ScanlatorAssociationRemover.new(fiction, scanlators(:one)).call

      assert_equal 0, fiction.reload.chapter_count
    end

    private

    def scanlator_chapter_count(fiction, scanlator)
      fiction.chapters.joins(:scanlators).where(scanlators: { id: scanlator.id }).count
    end
  end
end
