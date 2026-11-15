# frozen_string_literal: true

module ParagraphReports
  # Kill/keep snapshot: how many reports were created and fixed in a rolling window.
  class WindowStats
    WINDOW = 28.days

    attr_reader :window_days, :created_by_status, :fixed_in_window, :dismissed_in_window, :open_now

    def self.build(now: Time.zone.now, window: WINDOW)
      new(now:, window:).gather
    end

    def initialize(now:, window:)
      @now = now
      @window = window
    end

    def gather
      @window_days = (@window / 1.day).to_i
      range = (@now - @window)..@now
      @created_by_status = ParagraphReport.where(created_at: range).group(:status).count
      @fixed_in_window = ParagraphReport.fixed.where(resolved_at: range).count
      @dismissed_in_window = ParagraphReport.dismissed.where(resolved_at: range).count
      @open_now = ParagraphReport.open.count
      self
    end

    def created_open = created_by_status.fetch('open', 0)

    def created_fixed = created_by_status.fetch('fixed', 0)

    def created_dismissed = created_by_status.fetch('dismissed', 0)

    def created_total = created_by_status.values.sum

    def to_h
      {
        window_days:,
        created_total:,
        created_open:,
        created_fixed:,
        created_dismissed:,
        fixed_in_window:,
        dismissed_in_window:,
        open_now:
      }
    end
  end
end
