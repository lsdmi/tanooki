# frozen_string_literal: true

module Chapters
  # Daily pass: compress inline images in chapters posted yesterday.
  # The worker job passes max_body_bytes so a huge body cannot OOM the job container;
  # operator rake runs leave it nil to compress everything.
  class CompressRecent
    Result = Data.define(:day, :chapter_ids, :compressed, :unchanged, :skipped, :errors)

    def self.call(day: Time.current.to_date, max_body_bytes: nil)
      new(day, max_body_bytes).call
    end

    def initialize(day, max_body_bytes)
      @day = day.to_date
      @target_day = @day - 1.day
      @max_body_bytes = max_body_bytes
    end

    def call
      ids = chapter_ids_for_target_day
      oversized = oversized_chapter_ids(ids)
      tallies = compress_all(ids - oversized)
      Result.new(day: @day, chapter_ids: ids, skipped: oversized.size, **tallies)
    end

    private

    def compress_all(ids)
      tallies = { compressed: 0, unchanged: 0, errors: [] }
      ids.each { |chapter_id| record_outcome!(tallies, compress_one(chapter_id)) }
      tallies
    end

    def record_outcome!(tallies, outcome)
      case outcome
      when :compressed then tallies[:compressed] += 1
      when :unchanged then tallies[:unchanged] += 1
      else tallies[:errors] << outcome
      end
    end

    def chapter_ids_for_target_day
      range = @target_day.all_day
      Chapter
        .where(Arel.sql("#{Chapter::PUBLIC_TIME_SQL} BETWEEN ? AND ?"), range.begin, range.end)
        .order(:id)
        .pluck(:id)
    end

    def oversized_chapter_ids(ids)
      return [] if @max_body_bytes.nil? || ids.empty?

      ActionText::RichText
        .where(record_type: 'Chapter', name: 'content', record_id: ids)
        .where('LENGTH(body) > ?', @max_body_bytes)
        .pluck(:record_id)
        .each { |chapter_id| Rails.logger.warn("[CompressRecent] chapter=#{chapter_id} skipped: body over limit") }
    end

    def compress_one(chapter_id)
      result = CompressInlineImages.call(chapter_id)
      log_result(result)
      GC.start
      result.unchanged ? :unchanged : :compressed
    rescue StandardError => e
      Rails.logger.error("[CompressRecent] chapter=#{chapter_id} #{e.class}: #{e.message}")
      { chapter_id:, error: "#{e.class}: #{e.message}" }
    end

    def log_result(result)
      Rails.logger.info(
        "[CompressRecent] chapter=#{result.chapter_id} " \
        "compressed=#{result.images_compressed} bytes=#{result.before_bytes}->#{result.after_bytes} " \
        "unchanged=#{result.unchanged}"
      )
    end
  end
end
