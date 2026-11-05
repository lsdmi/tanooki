# frozen_string_literal: true

require 'test_helper'

module Contests
  class LockEntriesTest < ActiveSupport::TestCase
    setup do
      @contest = contests(:submissions)
      @entry = contest_entries(:accepted)
      @fiction = @entry.fiction
      @fiction.contest_entries.where.not(id: @entry.id).delete_all
      FictionGenre.find_or_create_by!(fiction: @fiction, genre_id: genres(:original).id)
    end

    test 'raises while submissions are still open' do
      error = assert_raises(LockEntries::Error) { LockEntries.call(contest: @contest) }

      assert_equal I18n.t('contests.lock.not_closed'), error.message
    end

    test 'raises for a cancelled contest' do
      contest = contests(:cancelled)
      error = assert_raises(LockEntries::Error) do
        LockEntries.call(contest:, at: contest.submissions_close_at + 1.minute)
      end

      assert_equal I18n.t('contests.lock.cancelled'), error.message
    end

    test 'marks accepted entry incomplete when requirements are unmet' do
      travel_to @contest.submissions_close_at + 1.minute do
        LockEntries.call(contest: @contest)
      end

      @entry.reload

      assert_predicate @entry, :incomplete?
      assert_predicate @entry.locked_snapshot, :present?
      assert_nil @entry.reviewed_at
    end

    test 'snapshot lists judged chapters with words and digest' do
      chapter = chapters(:one)
      plain = chapter.content.to_plain_text.to_s
      words = chapter.word_count.to_i

      travel_to @contest.submissions_close_at + 1.minute do
        LockEntries.call(contest: @contest)
      end

      row = @entry.reload.locked_snapshot.fetch('chapters').find { |item| item['chapter_id'] == chapter.id }

      assert_equal words, row['words']
      assert_equal Digest::SHA256.hexdigest(plain), row['digest']
    end

    test 'snapshot total_words sums chapter words' do
      expected = RequirementsProgress.new(@entry).judged_chapters.sum { |chapter| chapter.word_count.to_i }

      travel_to @contest.submissions_close_at + 1.minute do
        LockEntries.call(contest: @contest)
      end

      assert_equal expected, @entry.reload.locked_snapshot['total_words']
    end

    test 'marks qualified when every requirement is met' do
      @contest.update!(min_chapters: 1, min_words: nil, required_genre: nil, requires_completed: false)

      travel_to @contest.submissions_close_at + 1.minute do
        LockEntries.call(contest: @contest)
      end

      assert_predicate @entry.reload, :qualified?
    end

    test 'second lock is a no-op' do
      travel_to @contest.submissions_close_at + 1.minute do
        first = LockEntries.call(contest: @contest)
        snapshot = @entry.reload.locked_snapshot
        second = LockEntries.call(contest: @contest)

        assert_equal 1, first.locked_count
        assert_equal 0, second.locked_count
        assert_equal snapshot, @entry.reload.locked_snapshot
      end
    end

    test 'skips rejected entries' do
      rejected = contest_entries(:rejected)

      travel_to @contest.submissions_close_at + 1.minute do
        LockEntries.call(contest: @contest)
      end

      assert_nil rejected.reload.locked_snapshot
      assert_predicate rejected, :rejected?
    end

    test 'refreshes contest_entry_authors from the fiction team' do
      @entry.entry_authors.destroy_all

      travel_to @contest.submissions_close_at + 1.minute do
        LockEntries.call(contest: @contest)
      end

      assert_equal @fiction.users.ids.sort, @entry.reload.authors.ids.sort
      assert_predicate @entry.authors, :any?
    end

    test 'excludes chapters released after the deadline' do
      late = Chapter.create!(
        fiction: @fiction,
        user: users(:user_one),
        title: 'Після дедлайну',
        number: 99,
        content: 'слово ' * 120,
        status: :published,
        published_at: @contest.submissions_close_at + 1.hour,
        scanlator_ids: @fiction.scanlators.ids
      )

      travel_to @contest.submissions_close_at + 2.hours do
        LockEntries.call(contest: @contest)
      end

      ids = @entry.reload.locked_snapshot.fetch('chapters').pluck('chapter_id')

      assert_not_includes ids, late.id
    end
  end
end
