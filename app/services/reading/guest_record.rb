# frozen_string_literal: true

module Reading
  # One fiction's reading record from a guest's device (`guest_reading.js`), as posted after sign-in.
  # Malformed parts are dropped. A record with no fiction, or with neither a resume chapter nor a read chapter, is nil.
  # A resume_at in the future (a wrong device clock) is taken as now, so it can't outrank every later account write.
  class GuestRecord
    MAX_READS = 2_000

    attr_reader :fiction_id, :chapter_id, :resume_at, :locator, :read_chapter_ids

    def self.parse(raw)
      return unless raw.respond_to?(:to_h)

      raw = raw.to_h.symbolize_keys
      fiction_id = parse_id(raw[:fiction_id])
      chapter_id = parse_id(raw[:chapter_id])
      read_chapter_ids = parse_ids(raw[:read_chapter_ids])
      return unless fiction_id && (chapter_id || read_chapter_ids.any?)

      new(fiction_id:, chapter_id:, read_chapter_ids:, resume_at: parse_time(raw[:resume_at]),
          locator: ResumeLocator.parse(raw[:locator]))
    end

    def self.parse_ids(values)
      Array(values).filter_map { parse_id(it) }.uniq.first(MAX_READS)
    end

    def self.parse_id(value)
      id = Integer(value, exception: false) if value.is_a?(Integer) || value.is_a?(String)
      id if id&.positive?
    end

    def self.parse_time(value)
      time = Time.zone.iso8601(value) if value.is_a?(String)
      [time, Time.current].min if time
    rescue ArgumentError
      nil
    end

    private_class_method :parse_ids, :parse_id, :parse_time

    def initialize(fiction_id:, chapter_id:, read_chapter_ids:, resume_at:, locator:)
      @fiction_id = fiction_id
      @chapter_id = chapter_id
      @read_chapter_ids = read_chapter_ids
      @resume_at = resume_at
      @locator = locator
    end
  end
end
