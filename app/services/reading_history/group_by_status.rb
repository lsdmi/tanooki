# frozen_string_literal: true

module ReadingHistory
  # Buckets reading progress rows by library status for the history UI.
  class GroupByStatus
    def initialize(readings, chapter_fetcher:)
      @readings = readings
      @chapter_fetcher = chapter_fetcher
    end

    def call
      groups = Hash.new { |h, k| h[k] = [] }

      @readings.each do |reading|
        groups[reading.status.to_sym] << reading
      end

      groups
    end
  end
end
