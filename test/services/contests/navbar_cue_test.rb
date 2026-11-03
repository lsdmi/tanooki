# frozen_string_literal: true

require 'test_helper'

module Contests
  class NavbarCueTest < ActiveSupport::TestCase
    test 'hot during submissions with deadline subtitle' do
      cue = NavbarCue.call

      assert_predicate cue, :hot?
      assert_match(/Йде/, cue.subtitle)
      assert_match(/Конкурс подачі/, cue.subtitle)
    end

    test 'archive subtitle when only results remain' do
      Contest.active.find_each { |contest| contest.update!(cancelled_at: Time.current) }

      cue = NavbarCue.call

      assert_not cue.hot?
      assert_equal I18n.t('contests.nav.subtitle.archive'), cue.subtitle
    end
  end
end
