# frozen_string_literal: true

# Counts active, finished, postponed, and dropped readings for a fiction.
class BookmarksAccounter
  STATUS_ORDER = ReadingProgress.statuses.keys.freeze

  attr_reader :fiction

  def initialize(fiction:)
    @fiction = fiction
  end

  def call
    counts = fiction.readings.group(:status).count

    STATUS_ORDER.map { |status| count_for_status(counts, status) }
  end

  private

  def count_for_status(counts, status)
    counts[status] || counts[ReadingProgress.statuses[status]] || 0
  end
end
