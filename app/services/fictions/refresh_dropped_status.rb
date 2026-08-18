# frozen_string_literal: true

module Fictions
  # Weekly CI / operator pass: drop stale ongoing + never-started announced fictions.
  class RefreshDroppedStatus
    Result = Data.define(
      :scanned_ongoing,
      :scanned_announced,
      :dropped_ongoing,
      :dropped_announced,
      :total_ongoing,
      :total_announced,
      :total_dropped,
      :total_finished,
      :errors
    )

    EMPTY = Result.new(
      scanned_ongoing: 0,
      scanned_announced: 0,
      dropped_ongoing: 0,
      dropped_announced: 0,
      total_ongoing: 0,
      total_announced: 0,
      total_dropped: 0,
      total_finished: 0,
      errors: []
    ).freeze

    def self.call
      new.call
    end

    def call
      return EMPTY unless Rails.env.production?

      tallies = blank_tallies
      scan_scope!(tallies, Fiction.ongoing, scanned: :scanned_ongoing, dropped: :dropped_ongoing)
      scan_scope!(tallies, Fiction.announced, scanned: :scanned_announced, dropped: :dropped_announced)
      Result.new(**tallies, **catalog_totals)
    end

    private

    def blank_tallies
      {
        scanned_ongoing: 0,
        scanned_announced: 0,
        dropped_ongoing: 0,
        dropped_announced: 0,
        errors: []
      }
    end

    def catalog_totals
      {
        total_ongoing: Fiction.ongoing.count,
        total_announced: Fiction.announced.count,
        total_dropped: Fiction.dropped.count,
        total_finished: Fiction.finished.count
      }
    end

    def scan_scope!(tallies, scope, scanned:, dropped:)
      scope.find_each { |fiction| refresh_one!(tallies, fiction, scanned:, dropped:) }
    end

    def refresh_one!(tallies, fiction, scanned:, dropped:)
      tallies[scanned] += 1
      fiction.set_dropped_status
      tallies[dropped] += 1 if fiction.reload.dropped?
    rescue StandardError => e
      log_error(fiction, e)
      tallies[:errors] << { fiction_id: fiction.id, error: "#{e.class}: #{e.message}" }
    end

    def log_error(fiction, error)
      Rails.logger.error("[RefreshDroppedStatus] fiction=#{fiction.id} #{error.class}: #{error.message}")
    end
  end
end
