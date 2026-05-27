# frozen_string_literal: true

require 'test_helper'

module Chapters
  class SyncScanlatorAssociationsTest < ActiveSupport::TestCase
    setup do
      @chapter = chapters(:one)
      @scanlator_one = scanlators(:one)
      @scanlator_two = scanlators(:two)
      ChapterScanlator.find_or_create_by!(chapter: @chapter, scanlator: @scanlator_two)
    end

    test 'non-admin save keeps scanlator teams not listed in the form' do
      user = users(:user_two)

      SyncScanlatorAssociations.new([@scanlator_two.id.to_s], @chapter, user: user).call

      assert_equal [@scanlator_one.id, @scanlator_two.id].sort, @chapter.scanlators.ids.sort
    end

    test 'non-admin can remove only their own team from the chapter' do
      user = users(:user_two)

      SyncScanlatorAssociations.new([], @chapter, user: user).call

      assert_equal [@scanlator_one.id], @chapter.scanlators.ids
    end

    test 'non-admin cannot assign a team they do not manage' do
      user = users(:user_two)
      @chapter.chapter_scanlators.where.not(scanlator: @scanlator_two).destroy_all

      SyncScanlatorAssociations.new([@scanlator_one.id.to_s], @chapter.reload, user: user).call

      assert_equal [@scanlator_two.id], @chapter.scanlators.ids
    end

    test 'admin save replaces the full scanlator list' do
      admin = users(:user_one)

      SyncScanlatorAssociations.new([@scanlator_two.id.to_s], @chapter, user: admin).call

      assert_equal [@scanlator_two.id], @chapter.scanlators.ids
    end
  end
end
