# frozen_string_literal: true

require 'test_helper'

class FictionUpdatesPresenterTest < ActiveSupport::TestCase
  test 'last_three_days_updates returns grouped updates by day and fiction' do
    presenter = FictionUpdatesPresenter.new
    updates = presenter.last_three_days_updates

    assert_kind_of Array, updates
    assert updates.any?, 'Should have updates for at least one day'

    # Check structure of the first day's updates
    day_update = updates.first
    assert_includes day_update.keys, :day
    assert_includes day_update.keys, :date
    assert_includes day_update.keys, :updates

    # Check structure of the first fiction update
    fiction_update = day_update[:updates].first
    assert_equal 'one', fiction_update[:fiction_slug]
    assert_equal 'Test Fiction', fiction_update[:fiction_title]
    assert_equal 'One', fiction_update[:scanlator_title]
    assert_equal 'one', fiction_update[:scanlator_slug]
    assert_kind_of String, fiction_update[:chapters_created_at]
    assert_kind_of Integer, fiction_update[:chapters_count]
  end
end
