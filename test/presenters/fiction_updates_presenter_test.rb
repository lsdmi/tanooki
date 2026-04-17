# frozen_string_literal: true

require 'test_helper'

class FictionUpdatesPresenterTest < ActiveSupport::TestCase
  test 'last_three_days_updates returns grouped updates by day and fiction' do
    presenter = FictionUpdatesPresenter.new
    updates = presenter.last_three_days_updates

    assert_kind_of Array, updates
    assert_equal 3, updates.size

    day_with_releases = updates.find { |d| d[:updates].any? }
    assert day_with_releases, 'fixture should include at least one release in the window'

    assert_includes day_with_releases.keys, :day
    assert_includes day_with_releases.keys, :date
    assert_includes day_with_releases.keys, :updates

    fiction_update = day_with_releases[:updates].first
    assert_equal 'one', fiction_update[:fiction_slug]
    assert_equal 'Test Fiction', fiction_update[:fiction_title]
    assert_equal 'One', fiction_update[:scanlator_title]
    assert_equal 'one', fiction_update[:scanlator_slug]
    assert_kind_of String, fiction_update[:chapters_released_at]
    assert_kind_of Integer, fiction_update[:chapters_count]
  end

  test 'subscriptions_only returns no updates when user has no reading progress' do
    presenter = FictionUpdatesPresenter.new(user: users(:user_two), subscriptions_only: true)
    updates = presenter.last_three_days_updates

    assert_equal 3, updates.size
    assert(updates.all? { |d| d[:updates].empty? })
  end

  test 'subscriptions_only includes releases for fictions in the user library' do
    presenter = FictionUpdatesPresenter.new(user: users(:user_one), subscriptions_only: true)
    updates = presenter.last_three_days_updates

    assert_equal 3, updates.size
    assert(updates.any? { |d| d[:updates].any? }, 'Expected chapter releases for fictions on reading progress')
  end
end
