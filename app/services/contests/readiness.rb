# frozen_string_literal: true

module Contests
  # Publish checklist (§7.7.4). Publish stays blocked until every item is met.
  class Readiness
    Item = Data.define(:key, :met?, :label)

    CHECKS = %i[
      title tagline description cover dates prize_sum jurors criteria placeholder previewed
    ].freeze

    def self.call(contest) = new(contest).call

    def initialize(contest)
      @contest = contest
    end

    def call
      CHECKS.map { |key| Item.new(key:, met?: send(:"#{key}?"), label: label_for(key)) }
    end

    def ready?
      call.all?(&:met?)
    end

    def missing_keys
      call.reject(&:met?).map(&:key)
    end

    def mark_previewed!(at: Time.current)
      return if previewed?

      payload = contest.announcements_sent.is_a?(Hash) ? contest.announcements_sent.dup : {}
      payload['previewed_at'] = at.iso8601
      contest.update!(announcements_sent: payload)
    end

    def previewed?
      raw = contest.announcements_sent.is_a?(Hash) && contest.announcements_sent['previewed_at']
      return false if raw.blank?

      previewed_at = Time.zone.parse(raw.to_s)
      return false if previewed_at.blank?

      # Content edits after preview require another look (1s slack for same-request updates).
      previewed_at >= contest.updated_at - 1.second
    end

    private

    attr_reader :contest

    def label_for(key)
      I18n.t("admin.contests.readiness.items.#{key}")
    end

    def title? = contest.title.present?
    def tagline? = contest.tagline.present?
    def description? = contest.description.body.to_s.strip.present?
    def cover? = contest.cover.attached?

    def dates?
      times = schedule_times
      return false if times.any?(&:blank?)
      return false unless times.first.to_date >= Time.zone.today

      times.each_cons(2).all? { |earlier, later| earlier < later } && (times[2] - times[1]) >= 4.weeks
    end

    def schedule_times
      [contest.announced_at, contest.submissions_open_at, contest.submissions_close_at, contest.judging_close_at]
    end

    def prize_sum?
      place_cash = contest.prizes.place.sum(:cash_uah)
      place_cash == contest.prize_pool_uah.to_i + contest.carryover_uah.to_i
    end

    def jurors?
      jurors = contest.jurors.to_a
      return false if jurors.size < 3
      return false unless jurors.any?(&:chair?)

      juror_user_ids = jurors.map(&:user_id)
      ContestEntryAuthor.where(contest_entry_id: contest.entries.select(:id), user_id: juror_user_ids).none?
    end

    def criteria?
      list = Array(contest.criteria)
      return false if list.blank?

      list.sum { |row| row.is_a?(Hash) ? row['weight'].to_i : 0 } == 100
    end

    def placeholder?
      contest.entry_placeholder_cover.attached? ||
        Rails.root.join('app/assets/images/novel.webp').exist?
    end
  end
end
