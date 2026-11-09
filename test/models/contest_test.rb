# frozen_string_literal: true

require 'test_helper'

class ContestTest < ActiveSupport::TestCase
  test 'fixtures resolve expected phases' do
    %i[draft announced submissions judging results cancelled].each do |fixture|
      assert_equal fixture, contests(fixture).phase
    end
  end

  test 'published_at keeps real dates in draft until publish' do
    contest = contests(:draft)
    contest.update!(
      announced_at: 1.week.ago,
      submissions_open_at: 1.day.ago,
      submissions_close_at: 1.month.from_now,
      judging_close_at: 2.months.from_now,
      published_at: nil
    )

    assert_equal :draft, contest.phase
    assert_not_includes Contest.visible, contest
  end

  test 'visible excludes unpublished drafts' do
    assert_includes Contest.visible, contests(:announced)
    assert_not_includes Contest.visible, contests(:draft)
  end

  test 'active scope' do
    assert_includes Contest.active, contests(:submissions)
    assert_not_includes Contest.active, contests(:results)
  end

  test 'archived scope' do
    assert_includes Contest.archived, contests(:results)
    assert_includes Contest.archived, contests(:cancelled)
  end

  test 'rejects non-increasing dates' do
    contest = contests(:draft)
    contest.submissions_open_at = contest.announced_at - 1.day

    assert_not contest.valid?
    assert_includes contest.errors[:base],
                    I18n.t('activerecord.errors.models.contest.attributes.base.dates_not_increasing')
  end

  test 'criteria weights must sum to 100' do
    contest = contests(:draft)
    contest.criteria = [{ 'key' => 'idea', 'label' => 'Ідея', 'weight' => 40 }]

    assert_not contest.valid?
    assert_predicate contest.errors[:criteria], :any?
  end

  test 'jury_weight must be 0..100' do
    contest = contests(:draft)
    contest.jury_weight = 120

    assert_not contest.valid?
  end

  test 'awaiting_results after judging_close without results' do
    contest = contests(:judging)
    contest.update!(judging_close_at: 1.hour.ago, results_published_at: nil)

    assert_equal :awaiting_results, contest.phase
  end
end
