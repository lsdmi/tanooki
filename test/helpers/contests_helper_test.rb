# frozen_string_literal: true

require 'test_helper'

class ContestsHelperTest < ActionView::TestCase
  include ContestsHelper

  test 'requirements line lists kind deadline and volume' do
    contest = contests(:submissions)
    line = contest_submit_requirements_line(contest)

    assert_match(/ориджинал/i, line)
    assert_match(/10 000/, line)
    assert_match(/3/, line)
  end
end
