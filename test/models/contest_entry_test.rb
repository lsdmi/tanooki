# frozen_string_literal: true

require 'test_helper'

class ContestEntryTest < ActiveSupport::TestCase
  test 'fixtures cover every status' do
    statuses = ContestEntry.distinct.pluck(:status).sort

    assert_equal ContestEntry::STATUSES.sort, statuses
  end

  test 'requires fiction or legacy title' do
    entry = ContestEntry.new(
      contest: contests(:submissions),
      submitter: users(:user_one),
      status: :accepted,
      ai_usage: :none,
      submitted_at: Time.current
    )

    assert_not entry.valid?
    assert_predicate entry.errors[:base], :any?
  end

  test 'legacy title only allowed on past results contests' do
    entry = ContestEntry.new(
      contest: contests(:submissions),
      legacy_title: 'Архів',
      status: :qualified,
      ai_usage: :none,
      submitted_at: Time.current
    )

    assert_not entry.valid?
    assert_predicate entry.errors[:legacy_title], :any?
  end

  test 'legacy winner fixture is a valid legacy entry' do
    legacy = contest_entries(:legacy_winner)

    assert_predicate legacy, :valid?
    assert_predicate legacy, :legacy?
  end

  test 'soft delete fiction withdraws open entries' do
    fiction = fictions(:one)
    entry = contest_entries(:accepted)

    assert_equal fiction.id, entry.fiction_id

    fiction.destroy

    assert_predicate entry.reload, :withdrawn?
  end
end
