# frozen_string_literal: true

module Fictions
  # Weekly CI / operator pass: mark unfinished fictions as dropped after 90 days of inactivity.
  class RefreshDroppedStatus
    Result = Data.define(:checked, :dropped, :errors)

    def self.call
      new.call
    end

    def call
      return Result.new(checked: 0, dropped: 0, errors: []) unless Rails.env.production?

      tallies = { checked: 0, dropped: 0, errors: [] }
      Fiction.find_each { |fiction| refresh_one!(tallies, fiction) }
      Result.new(**tallies)
    end

    private

    def refresh_one!(tallies, fiction)
      return if fiction.finished?

      tallies[:checked] += 1
      record_drop!(tallies, fiction)
    rescue StandardError => e
      log_error(fiction, e)
      tallies[:errors] << { fiction_id: fiction.id, error: "#{e.class}: #{e.message}" }
    end

    def record_drop!(tallies, fiction)
      was_dropped = fiction.dropped?
      fiction.set_dropped_status
      tallies[:dropped] += 1 if !was_dropped && fiction.reload.dropped?
    end

    def log_error(fiction, error)
      Rails.logger.error("[RefreshDroppedStatus] fiction=#{fiction.id} #{error.class}: #{error.message}")
    end
  end
end
