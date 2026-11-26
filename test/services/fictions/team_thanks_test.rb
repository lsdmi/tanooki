# frozen_string_literal: true

require 'test_helper'

module Fictions
  class TeamThanksTest < ActiveSupport::TestCase
    setup do
      @fiction = fictions(:one)
      FictionScanlator.create!(fiction: @fiction, scanlator: scanlators(:two))
    end

    test 'sums thanks per team, a chapter shared by two teams counts for both' do
      link_teams(chapters(:one), scanlators(:one))
      link_teams(chapters(:two), scanlators(:one), scanlators(:two))
      chapters(:one).update_column(:thanks_count, 5)
      chapters(:two).update_column(:thanks_count, 3)

      assert_equal({ scanlators(:one).id => 8, scanlators(:two).id => 3 }, TeamThanks.call(@fiction))
    end

    test 'draft chapters do not count' do
      link_teams(chapters(:one), scanlators(:one))
      link_teams(chapters(:two), scanlators(:two))
      chapters(:one).update_column(:thanks_count, 5)
      chapters(:two).update!(status: :draft)
      chapters(:two).update_column(:thanks_count, 10)

      assert_equal({ scanlators(:one).id => 5 }, TeamThanks.call(@fiction))
    end

    private

    def link_teams(chapter, *teams)
      ChapterScanlator.where(chapter:).delete_all
      teams.each { |team| ChapterScanlator.create!(chapter:, scanlator: team) }
    end
  end
end
