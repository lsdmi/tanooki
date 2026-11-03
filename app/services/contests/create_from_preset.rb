# frozen_string_literal: true

module Contests
  # Builds an unpublished contest draft from a format preset (§7.7.1).
  class CreateFromPreset
    RAW_REQUIREMENT_KEYS = %w[min_chapters min_words max_words judged_word_cap].freeze

    class Error < StandardError; end

    def self.call(**) = new(**).call

    def initialize(preset:, submissions_open_at:, prize_pool_uah:, title: nil)
      @preset = preset.is_a?(Preset) ? preset : Preset.find!(preset)
      @submissions_open_at = parse_time(submissions_open_at)
      @prize_pool_uah = prize_pool_uah.to_i
      @title = title.presence || default_title
      raise Error, 'submissions_open_at required' if @submissions_open_at.blank?
      raise Error, 'prize_pool_uah must be >= 0' if @prize_pool_uah.negative?
    end

    def call
      Contest.transaction do
        contest = Contest.create!(contest_attributes)
        PresetPrizes.call(contest:, preset:, prize_pool_uah:)
        contest
      end
    end

    private

    attr_reader :preset, :submissions_open_at, :prize_pool_uah, :title

    def parse_time(value)
      value.is_a?(Time) ? value : Time.zone.parse(value.to_s)
    end

    def contest_attributes
      {
        title:, kind: preset.kind, preset_key: preset.key, preset_version: preset.version,
        required_genre: preset.required_genre, jury_weight: preset.jury_weight, criteria: preset.criteria,
        prize_pool_uah:
      }.merge(schedule_attributes, requirement_attributes)
    end

    def schedule_attributes
      durations = preset.durations
      {
        announced_at: submissions_open_at - durations.announce,
        submissions_open_at:,
        submissions_close_at: submissions_open_at + durations.submissions,
        judging_close_at: submissions_open_at + durations.submissions + durations.judging
      }
    end

    def requirement_attributes
      req = preset.requirements
      {
        requires_new_work: req.fetch('requires_new_work', true),
        requires_completed: req.fetch('requires_completed', false),
        judged_chapters_scope: req.fetch('judged_chapters_scope', 'until_close'),
        max_content_rating: req.fetch('max_content_rating', 18),
        max_entries_per_user: req.fetch('max_entries_per_user', 1)
      }.merge(RAW_REQUIREMENT_KEYS.to_h { |key| [key.to_sym, req[key]] })
    end

    def default_title
      I18n.t('contests.presets.draft_title', preset: preset.label)
    end
  end
end
