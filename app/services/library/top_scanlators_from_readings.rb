# frozen_string_literal: true

module Library
  # Returns the two scanlator teams most frequent in a user's readings.
  class TopScanlatorsFromReadings
    def initialize(readings)
      @readings = readings
    end

    def call
      scanlator_counts = scanlators_from_readings.each_with_object(Hash.new(0)) do |scanlator, counts|
        counts[scanlator] += 1
      end

      scanlator_counts.sort_by { |_, count| -count }.first(2).map(&:first)
    end

    private

    attr_reader :readings

    def scanlators_from_readings
      readings.flat_map { |reading| reading.fiction.scanlators }
    end
  end
end
