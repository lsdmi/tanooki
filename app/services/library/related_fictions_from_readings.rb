# frozen_string_literal: true

module Library
  # Builds a deduplicated list of genre-related fictions from the user's reading history.
  class RelatedFictionsFromReadings
    def initialize(readings, limit = 5, exclude_ids: Set.new)
      @readings = readings
      @limit = limit
      @related_fictions = []
      @fiction_ids = Set.new
      @exclude_ids = exclude_ids
    end

    def call
      @readings.each do |reading|
        process_reading(reading)
        break if reached_limit?
      end
      @related_fictions
    end

    private

    def process_reading(reading)
      fiction = reading.fiction
      return unless fiction

      fiction.related_fictions.each do |related|
        add_related_fiction(related)
        break if reached_limit?
      end
    end

    def add_related_fiction(related)
      return if @fiction_ids.include?(related.id)
      return if @exclude_ids.include?(related.id)

      @related_fictions << related
      @fiction_ids << related.id
    end

    def reached_limit?
      @related_fictions.size >= @limit
    end
  end
end
