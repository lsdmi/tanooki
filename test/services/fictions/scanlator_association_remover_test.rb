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

    private

    def scanlator_chapter_count(fiction, scanlator)
      fiction.chapters.joins(:scanlators).where(scanlators: { id: scanlator.id }).count
    end
  end
end
