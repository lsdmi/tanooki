# frozen_string_literal: true

require 'test_helper'

class HomeRecentlyUpdatedTest < ActionDispatch::IntegrationTest
  test 'recently updated section shows update cards under popular' do
    Search::TagCounts.stub(:call, {}) { get root_url }

    assert_select '#home-recently-updated', text: 'Нові Релізи'
    assert_select '[aria-label="Нові Релізи"] article', minimum: 1
    assert_select '[aria-label="Нові Релізи"] a[href*="chapters"]', minimum: 1
  end

  test 'recently updated section uses mobile column slider layout' do
    Search::TagCounts.stub(:call, {}) { get root_url }

    assert_select '[aria-label="Нові Релізи"].snap-x.snap-mandatory', minimum: 1
    assert_select '[aria-label="Нові Релізи"].snap-x .snap-start.flex-col', minimum: 1
  end
end
