# frozen_string_literal: true

require 'test_helper'

module Contests
  class ShowPresenterSectionsTest < ActiveSupport::TestCase
    setup do
      @reader = users(:user_two)
    end

    def presenter(contest, user = nil)
      ShowPresenter.new(contest: contests(contest), user:)
    end

    test 'sections are ordered data with visibility flags' do
      sections = presenter(:submissions).sections
      visible = sections.select { |section| section[:visible] }.pluck(:id)

      assert_equal :hero, sections.first[:id]
      assert_empty %i[how_to_join works] - visible
    end

    test 'submissions phase hides results and my_participation for guests' do
      visible = presenter(:submissions).sections.select { |section| section[:visible] }.pluck(:id)

      assert_empty %i[results my_participation] & visible
    end

    test 'my_participation is visible to participants only' do
      contest_entries(:accepted).update!(submitter_id: @reader.id)
      visible = presenter(:submissions, @reader).visible_sections.pluck(:id)

      assert_includes visible, :my_participation
    end

    test 'results phase puts results right after hero and hides join sections' do
      contest_entries(:accepted).update!(submitter_id: @reader.id)
      subject = presenter(:results, @reader)

      visible = subject.visible_sections.pluck(:id)

      assert_equal %i[hero results], subject.sections.first(2).pluck(:id)
      assert_includes visible, :results
    end

    test 'results phase hides join sections' do
      contest_entries(:accepted).update!(submitter_id: @reader.id)
      visible = presenter(:results, @reader).visible_sections.pluck(:id)

      assert_empty %i[how_to_join my_participation] & visible
    end

    test 'announced hides works and results' do
      visible = presenter(:announced).visible_sections.pluck(:id)

      assert_not_includes visible, :works
      assert_not_includes visible, :results
    end

    test 'past winners section appears when other contests have winners' do
      assert_includes presenter(:submissions).visible_sections.pluck(:id), :past_winners
      assert_not_includes presenter(:results).visible_sections.pluck(:id), :past_winners
    end

    test 'nav items are limited to visible nav sections' do
      ids = presenter(:announced).nav_items.pluck(:id)

      assert_includes ids, :how_to_join
      assert_not_includes ids, :works
    end

    test 'summary facts has six entries' do
      facts = presenter(:submissions).summary_facts

      assert_equal 6, facts.size
      assert(facts.all? { |fact| fact[:label].present? && fact[:value].present? })
      assert_equal %i[deadline fee first_prize who what genre_rating], facts.pluck(:key)
    end

    test 'prize pool total sums pool, donations and carryover' do
      contest = contests(:submissions)
      contest.update!(donations_uah: 500, carryover_uah: 250)

      assert_equal 3750, ShowPresenter.new(contest:, user: nil).prize_pool_total
    end

    test 'gallery lists accepted entries with a released chapter' do
      entries = load_gallery(presenter(:submissions))

      assert_equal [contest_entries(:accepted)], entries
    end

    test 'gallery omits rejected entries' do
      entries = load_gallery(presenter(:submissions))

      assert_not_includes entries, contest_entries(:rejected)
    end

    test 'gallery skips entries without released chapters' do
      Chapter.where(fiction_id: fictions(:one).id).find_each { |chapter| chapter.update!(status: :draft) }

      assert_empty presenter(:submissions).gallery_entries
    end

    test 'gallery orders by final rank after results' do
      contest = contests(:results)
      first = ContestEntry.create!(contest:, fiction: fictions(:one), status: :qualified, submitted_at: 1.month.ago,
                                   final_rank: 2)
      second = ContestEntry.create!(contest:, fiction: fictions(:two), status: :qualified, submitted_at: 1.month.ago,
                                    final_rank: 1)

      assert_equal [second, first], load_gallery(ShowPresenter.new(contest:, user: nil))
    end

    test 'timeline marks the current phase' do
      steps = presenter(:submissions).timeline_steps

      assert_equal %i[announced submissions judging awaiting_results results], steps.pluck(:key)
      assert_equal [:submissions], steps.select { |step| step[:current] }.pluck(:key)
    end

    test 'donation goals are prizes with unlock thresholds' do
      contest = contests(:results)
      goal = contest.prizes.create!(title: 'Ціль', kind: :nomination, position: 5, unlock_at_uah: 5000)

      assert_equal [goal], ShowPresenter.new(contest:, user: nil).donation_goals
    end

    private

    # Touch the preloaded associations the way the gallery cards do (Bullet flags unused eager loads).
    def load_gallery(subject)
      subject.gallery_entries.to_a.each { |entry| [entry.fiction.cover.attached?, entry.fiction.genres.to_a] }
    end
  end
end
