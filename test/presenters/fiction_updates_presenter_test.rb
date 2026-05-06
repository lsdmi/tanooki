# frozen_string_literal: true

require 'test_helper'

class FictionUpdatesPresenterTest < ActiveSupport::TestCase
  test 'last_three_days_updates returns three day buckets' do
    updates = FictionUpdatesPresenter.new.last_three_days_updates

    assert_kind_of Array, updates
    assert_equal 3, updates.size
  end

  test 'last_three_days_updates fixture includes at least one release in the window' do
    updates = FictionUpdatesPresenter.new.last_three_days_updates
    day_with_releases = updates.find { |d| d[:updates].any? }

    assert_predicate day_with_releases, :present?
  end

  test 'last_three_days_updates each day entry includes day date and updates keys' do
    day_with_releases = day_with_releases_from_presenter

    assert_includes day_with_releases.keys, :day
    assert_includes day_with_releases.keys, :date
    assert_includes day_with_releases.keys, :updates
  end

  test 'last_three_days_updates fiction update includes expected metadata' do
    fiction_update = first_fiction_update_from_presenter

    expected = {
      fiction_slug: 'one',
      fiction_title: 'Test Fiction',
      scanlator_title: 'One',
      scanlator_slug: 'one'
    }

    assert_equal expected, fiction_update.slice(:fiction_slug, :fiction_title, :scanlator_title, :scanlator_slug)
  end

  test 'last_three_days_updates fiction update includes chapter timing fields' do
    fiction_update = first_fiction_update_from_presenter

    assert_kind_of String, fiction_update[:chapters_released_at]
    assert_kind_of Integer, fiction_update[:chapters_count]
  end

  test 'subscriptions_only returns no updates when user has no reading progress' do
    presenter = FictionUpdatesPresenter.new(user: users(:user_two), subscriptions_only: true)
    updates = presenter.last_three_days_updates

    assert_equal 3, updates.size
    assert_empty(updates.flat_map { |d| d[:updates] })
  end

  test 'subscriptions_only includes releases for fictions in the user library' do
    presenter = FictionUpdatesPresenter.new(user: users(:user_one), subscriptions_only: true)
    updates = presenter.last_three_days_updates

    assert_equal 3, updates.size
    assert_not_empty(updates.flat_map { |d| d[:updates] })
  end

  private

  def day_with_releases_from_presenter
    updates = FictionUpdatesPresenter.new.last_three_days_updates
    updates.find { |d| d[:updates].any? }
  end

  def first_fiction_update_from_presenter
    day_with_releases_from_presenter[:updates].first
  end
end
