# frozen_string_literal: true

require 'test_helper'

class FictionListingScopesTest < ActiveSupport::TestCase
  setup do
    @fiction = fictions(:one)
    @other = fictions(:two)
    @fiction.scanlator_ids = @fiction.scanlators.ids
    @other.scanlator_ids = @other.scanlators.ids
  end

  test 'finished is completed_at present' do
    @fiction.update!(completed_at: Time.current)

    assert_includes Fiction.finished, @fiction
    assert_not_includes Fiction.finished, @other
  end

  test 'live is recent last_chapter_at without complete' do
    @fiction.update!(chapter_count: 3, last_chapter_at: 1.day.ago, completed_at: nil)

    assert_includes Fiction.live, @fiction
    assert_not_includes Fiction.live, @other
  end

  test 'announced is a listing with no public chapter time' do
    @fiction.update!(chapter_count: 4, last_chapter_at: nil, completed_at: nil)

    assert_includes Fiction.announced, @fiction
    assert_not_includes Fiction.stale, @fiction
    assert_not_includes Fiction.live, @fiction
  end

  test 'stale is old last_chapter_at without complete' do
    @fiction.update!(chapter_count: 3, last_chapter_at: 91.days.ago, completed_at: nil)

    assert_includes Fiction.stale, @fiction
    assert_not_includes Fiction.live, @fiction
    assert_not_includes Fiction.finished, @fiction
  end

  test 'recent Thursday window includes last Thursday through Wednesday night' do
    membership = {
      '2026-09-09 23:59:59' => false,
      '2026-09-10 00:00:00' => true,
      '2026-09-10 18:20:00' => true,
      '2026-09-16 23:59:59' => true,
      '2026-09-17 00:00:00' => false,
      '2026-09-17 10:00:00' => false
    }

    ['2026-09-17 14:00', '2026-09-17 18:29', '2026-09-18 01:00'].each do |run_at|
      travel_to Time.zone.parse(run_at) do
        membership.each do |created_at, included|
          @fiction.update!(created_at: Time.zone.parse(created_at))

          if included
            assert_includes Fiction.recent, @fiction, "#{created_at} should be listed at #{run_at}"
          else
            assert_not_includes Fiction.recent, @fiction, "#{created_at} should wait until next week at #{run_at}"
          end
        end
      end
    end
  end

  test 'recent Thursday windows tile without overlap' do
    @fiction.update!(created_at: Time.zone.parse('2026-09-10 10:00'))

    travel_to Time.zone.parse('2026-09-10 18:29') do
      assert_not_includes Fiction.recent, @fiction
    end

    travel_to Time.zone.parse('2026-09-17 18:29') do
      assert_includes Fiction.recent, @fiction
    end

    travel_to Time.zone.parse('2026-09-24 14:00') do
      assert_not_includes Fiction.recent, @fiction
    end
  end

  test 'recent lists newest first' do
    travel_to Time.zone.parse('2026-09-17 18:29') do
      @fiction.update!(created_at: Time.zone.parse('2026-09-14 12:00'))
      @other.update!(created_at: Time.zone.parse('2026-09-16 12:00'))

      assert_equal [@other.id, @fiction.id], Fiction.recent.where(id: [@fiction.id, @other.id]).map(&:id)
    end
  end
end
