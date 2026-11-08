# frozen_string_literal: true

require 'test_helper'

module Chapters
  class TeamFilterTest < ActiveSupport::TestCase
    setup do
      @fiction = fictions(:one)
      @one = scanlators(:one)
      @two = scanlators(:two)
      FictionScanlator.create!(fiction: @fiction, scanlator: @two)
      @theirs = Chapter.create!(
        fiction: @fiction, user: users(:user_two), title: 'Other', number: 3, content: 'x' * 500,
        scanlator_ids: [@two.id]
      )
      ChapterScanlator.create!(chapter: @theirs, scanlator: @two) unless @theirs.scanlators.exists?(@two.id)
      @listed = Library::ChapterCatalog.listed_chapters(@fiction)
      @teams = Fictions::TeamsByChapters.call(@fiction)
      @sections = ListSectionIndex.new(@listed, order: :asc).call
    end

    test 'inactive filter leaves sections untouched' do
      filter = TeamFilter.new(nil, teams: @teams)

      assert_equal @sections, filter.sections(@sections, @listed)
    end

    test 'active filter trims chapter_ids and chapter_keys to the chosen team' do
      filter = TeamFilter.new(@two.id, teams: @teams)
      section = filter.sections(@sections, @listed).sole

      assert_equal [@theirs.id], section[:chapter_ids]
      assert_equal [ReadingChapterRead.chapter_key(@theirs)], section[:chapter_keys]
    end

    test 'listed returns only chapters for the chosen team' do
      filter = TeamFilter.new(@two.id, teams: @teams)

      assert_equal [@theirs], filter.listed(@listed)
    end
  end
end
