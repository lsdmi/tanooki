# frozen_string_literal: true

require 'test_helper'

module Contests
  class CreateFromPresetTest < ActiveSupport::TestCase
    test 'each preset yields a valid persisted draft' do
      each_preset_contest do |_preset, contest, _open_at|
        assert_predicate contest, :persisted?
        assert_equal :draft, contest.phase
        assert_predicate contest, :valid?
      end
    end

    test 'each preset records its key and version' do
      each_preset_contest do |preset, contest, _open_at|
        assert_equal preset.key, contest.preset_key
        assert_equal preset.version, contest.preset_version
      end
    end

    test 'each preset schedules dates from the open date' do
      each_preset_contest do |preset, contest, open_at|
        assert_equal open_at, contest.submissions_open_at
        assert_equal open_at - preset.durations.announce, contest.announced_at
        assert_equal open_at + preset.durations.submissions, contest.submissions_close_at
      end
    end

    test 'each preset has a matching place prize sum' do
      each_preset_contest do |_preset, contest, _open_at|
        assert_equal 3000, contest.prizes.place.sum(:cash_uah)
      end
    end

    private

    def each_preset_contest
      Preset.all.to_a.each do |preset|
        open_at = 5.weeks.from_now.beginning_of_day
        contest = CreateFromPreset.call(
          preset:,
          submissions_open_at: open_at,
          prize_pool_uah: 3000,
          title: "Тест #{preset.key}"
        )
        yield preset, contest, open_at
      end
    end
  end
end
