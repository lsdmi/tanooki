# frozen_string_literal: true

require 'test_helper'

module Contests
  class JudgedChaptersTest < ActiveSupport::TestCase
    setup do
      @contest = contests(:submissions)
      @fiction = fictions(:one)
    end

    test 'includes released chapters before the close' do
      ids = JudgedChapters.call(contest: @contest, fiction: @fiction).pluck(:id)

      assert_includes ids, chapters(:one).id
      assert_includes ids, chapters(:two).id
    end

    test 'in_window excludes chapters public before submissions open' do
      @contest.update!(judged_chapters_scope: :in_window)
      early = nil
      travel_to(@contest.submissions_open_at - 1.day) do
        early = Chapter.create!(
          fiction: @fiction,
          user: users(:user_one),
          title: 'До відкриття подачі',
          number: 50,
          content: 'слово ' * 120,
          status: :published,
          published_at: Time.current,
          scanlator_ids: @fiction.scanlators.ids
        )
      end

      ids = JudgedChapters.call(contest: @contest, fiction: @fiction).pluck(:id)

      assert_not_includes ids, early.id
      assert_includes ids, chapters(:two).id
    end

    test 'returns none without a fiction' do
      assert_empty JudgedChapters.call(contest: @contest, fiction: nil)
    end
  end
end
