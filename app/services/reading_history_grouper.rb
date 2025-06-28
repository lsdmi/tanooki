# frozen_string_literal: true

class ReadingHistoryGrouper
  def initialize(readings, chapter_fetcher:)
    @readings = readings
    @chapter_fetcher = chapter_fetcher
  end

  def group
    groups = Hash.new { |h, k| h[k] = [] }

    @readings.each do |reading|
      group = group_for(reading)
      groups[group] << reading
    end

    groups
  end

  private

  def group_for(reading)
    reading.status.to_sym
  end
end
