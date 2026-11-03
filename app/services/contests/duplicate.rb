# frozen_string_literal: true

module Contests
  # Copies a contest into a new draft with shifted dates, without theme/cover (§7.7.2).
  class Duplicate
    DEFAULT_WEEKS_UNTIL_OPEN = 4
    COPIED_ATTRIBUTES = %i[
      kind preset_key preset_version required_genre_id requires_new_work requires_completed
      min_chapters min_words max_words judged_word_cap judged_chapters_scope max_content_rating
      max_entries_per_user jury_weight prize_pool_uah donation_url
    ].freeze
    PRIZE_ATTRIBUTES = %i[title kind place position cash_uah unlock_at_uah perks avatar_id].freeze

    class Error < StandardError; end

    def self.call(**) = new(**).call

    def initialize(contest:, weeks_until_open: DEFAULT_WEEKS_UNTIL_OPEN, title: nil)
      @source = contest
      @weeks_until_open = weeks_until_open.to_i
      @title = title.presence || I18n.t('contests.presets.duplicate_title', title: contest.title)
      raise Error, 'contest required' if source.blank?
    end

    def call
      Contest.transaction do
        draft = Contest.create!(copied_attributes)
        copy_rich_text(draft)
        copy_prizes(draft)
        copy_jurors(draft)
        copy_placeholder_cover(draft)
        draft
      end
    end

    private

    attr_reader :source, :weeks_until_open, :title

    def copied_attributes
      open_at = next_open_at
      shift = open_at - source.submissions_open_at
      source.slice(*COPIED_ATTRIBUTES).symbolize_keys.merge(derived_attributes, shifted_dates(open_at, shift))
    end

    def next_open_at
      current = source.submissions_open_at
      weeks_until_open.weeks.from_now.change(hour: current.hour, min: current.min, sec: current.sec)
    end

    def derived_attributes
      {
        title:,
        source_contest: source,
        criteria: Array(source.criteria).map(&:dup),
        carryover_uah: source.carryover_uah.to_i + leftover_pool,
        sponsors: Array(source.sponsors).map(&:dup)
      }
    end

    def shifted_dates(open_at, shift)
      {
        announced_at: source.announced_at + shift,
        submissions_open_at: open_at,
        submissions_close_at: source.submissions_close_at + shift,
        judging_close_at: source.judging_close_at + shift
      }
    end

    def copy_rich_text(draft)
      draft.update!(rules: source.rules.body) if source.rules.body.present?
    end

    def leftover_pool
      report = source.report
      return 0 unless report.is_a?(Hash)

      report['carryover_uah'].to_i
    end

    def copy_prizes(draft)
      source.prizes.order(:position, :id).each { |prize| draft.prizes.create!(prize.slice(*PRIZE_ATTRIBUTES)) }
    end

    def copy_jurors(draft)
      source.jurors.find_each do |juror|
        draft.jurors.create!(
          user_id: juror.user_id,
          role: juror.role,
          public_bio: juror.public_bio
        )
      end
    end

    def copy_placeholder_cover(draft)
      return unless source.entry_placeholder_cover.attached?

      draft.entry_placeholder_cover.attach(
        io: StringIO.new(source.entry_placeholder_cover.download),
        filename: source.entry_placeholder_cover.filename.to_s,
        content_type: source.entry_placeholder_cover.content_type
      )
    end
  end
end
