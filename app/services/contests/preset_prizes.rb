# frozen_string_literal: true

module Contests
  # Creates place prizes, nomination prizes, and donation-goal unlocks for a preset contest (§7.7.1).
  class PresetPrizes
    PLACE_TITLES = { 1 => '1 місце', 2 => '2 місце', 3 => '3 місце' }.freeze
    NOMINATION_TITLES = {
      'readers_choice' => 'Вибір читачів',
      'jury_choice' => 'Вибір журі',
      'debut' => 'Дебют',
      'continuation' => 'Продовження'
    }.freeze

    def self.call(**) = new(**).call

    def initialize(contest:, preset:, prize_pool_uah:)
      @contest = contest
      @preset = preset
      @prize_pool_uah = prize_pool_uah
    end

    def call
      build_place_prizes
      build_nomination_prizes
      apply_donation_goals
    end

    private

    attr_reader :contest, :preset, :prize_pool_uah

    def build_place_prizes
      preset.prize_split.sort.each_with_index do |(place, percent), position|
        contest.prizes.create!(
          position:,
          title: PLACE_TITLES.fetch(place),
          kind: :place,
          place:,
          cash_uah: (prize_pool_uah * percent / 100.0).round
        )
      end
    end

    def build_nomination_prizes
      start = next_position
      # continuation is unlocked via donation goal
      preset.nominations.reject { |key| key == 'continuation' }.each_with_index do |key, offset|
        contest.prizes.create!(position: start + offset, title: NOMINATION_TITLES.fetch(key),
                               kind: :nomination, cash_uah: 0)
      end
    end

    def apply_donation_goals
      preset.donation_goals.each do |goal|
        at = goal.fetch('at_uah').to_i
        cash = goal['cash_uah'].to_i
        Array(goal['unlocks']).map(&:to_s).each { |key| unlock_prize(key, at:, cash:) }
      end
    end

    def unlock_prize(key, at:, cash:)
      return create_continuation_prize(at) if key == 'continuation'

      contest.prizes.find_by!(title: NOMINATION_TITLES.fetch(key)).update!(unlock_at_uah: at, cash_uah: cash)
    end

    def create_continuation_prize(unlock_at_uah)
      contest.prizes.create!(
        position: next_position,
        title: NOMINATION_TITLES.fetch('continuation'),
        kind: :continuation,
        cash_uah: 0,
        unlock_at_uah:
      )
    end

    def next_position
      contest.prizes.maximum(:position).to_i + 1
    end
  end
end
