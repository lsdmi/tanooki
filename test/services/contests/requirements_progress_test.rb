# frozen_string_literal: true

require 'test_helper'

module Contests
  class RequirementsProgressTest < ActiveSupport::TestCase
    setup do
      @entry = contest_entries(:accepted)
      @contest = @entry.contest
      @fiction = @entry.fiction
      @fiction.contest_entries.where.not(id: @entry.id).delete_all
      FictionGenre.find_or_create_by!(fiction: @fiction, genre_id: genres(:original).id)
    end

    test 'lists a chapters item for a submissions contest' do
      item = RequirementsProgress.call(@entry).find { |row| row.key == :chapters }

      assert item
      assert_operator item.current, :>=, 0
      assert_equal @contest.min_chapters, item.required
    end

    test 'marks genre when the required genre is present' do
      @contest.update!(required_genre: genres(:original))
      item = RequirementsProgress.call(@entry).find { |row| row.key == :genre }

      assert_predicate item, :met?
    end

    test 'completed item appears when the contest requires a finished work' do
      @contest.update!(requires_completed: true)
      @fiction.update!(completed_at: nil)
      item = RequirementsProgress.call(@entry).find { |row| row.key == :completed }

      assert_not item.met?

      @fiction.update!(completed_at: Time.current)
      item = RequirementsProgress.call(@entry.reload).find { |row| row.key == :completed }

      assert_predicate item, :met?
    end
  end
end
