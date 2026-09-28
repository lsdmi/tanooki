# frozen_string_literal: true

module Chapters
  # One batch of the inline image backfill: scans a window of rich text ids for live chapter
  # bodies that embed base64 images and compresses them with CompressInlineImages.
  # Windows are small because every scan pulls bodies through the database's small buffer pool.
  class CompressBackfill
    # before_bytes/after_bytes cover only rewritten bodies; candidate_bytes is every candidate body.
    Result = Data.define(
      :after_id, :to_id, :done, :candidates, :candidate_bytes, :compressed, :unchanged, :skipped, :errors,
      :before_bytes, :after_bytes
    )
    Options = Data.define(:scan_size, :max_body_bytes, :min_body_bytes, :dry_run)

    def self.call(after_id:, scan_size:, max_body_bytes: nil, min_body_bytes: nil, dry_run: false)
      new(after_id, Options.new(scan_size:, max_body_bytes:, min_body_bytes:, dry_run:)).call
    end

    # Laptop pass for bodies too large for the worker; yields each batch result.
    def self.run_local(after_id:, min_body_bytes:, scan_size: 500, pause: 2)
      loop do
        result = call(after_id:, scan_size:, min_body_bytes:)
        yield result
        break result if result.done

        after_id = result.to_id
        sleep pause
      end
    end

    def initialize(after_id, options)
      @after_id = after_id.to_i
      @options = options
      @to_id = @after_id + options.scan_size
    end

    def call
      tallies = { compressed: 0, unchanged: 0, skipped: [], errors: [], before_bytes: 0, after_bytes: 0 }
      candidates = find_candidates
      candidates.each { |chapter_id, body_bytes| process(tallies, chapter_id, body_bytes) }
      Result.new(after_id: @after_id, to_id: @to_id, done: @to_id >= max_rich_text_id,
                 candidates: candidates.size, candidate_bytes: candidates.sum(&:last), **tallies)
    end

    private

    def find_candidates
      ActionText::RichText
        .joins('INNER JOIN chapters ON chapters.id = action_text_rich_texts.record_id AND chapters.deleted_at IS NULL')
        .where(record_type: 'Chapter', name: 'content', id: (@after_id + 1)..@to_id)
        .where("LOCATE('base64,', action_text_rich_texts.body) > 0")
        .order(:id)
        .pluck(:record_id, Arel.sql('LENGTH(action_text_rich_texts.body)'))
    end

    def max_rich_text_id
      ActionText::RichText.unscoped.maximum(:id).to_i
    end

    def process(tallies, chapter_id, body_bytes)
      return tallies[:skipped] << skip(chapter_id, body_bytes) unless in_size_range?(body_bytes)
      return log("chapter=#{chapter_id} body=#{body_bytes} dry_run") if @options.dry_run

      record!(tallies, CompressInlineImages.call(chapter_id))
    rescue StandardError => e
      tallies[:errors] << failure(chapter_id, e)
    ensure
      GC.start
    end

    def failure(chapter_id, error)
      message = "#{error.class}: #{error.message}"
      Rails.logger.error("[CompressBackfill] chapter=#{chapter_id} #{message}")
      { chapter_id:, error: message }
    end

    def in_size_range?(body_bytes)
      return false if @options.max_body_bytes && body_bytes > @options.max_body_bytes
      return false if @options.min_body_bytes && body_bytes < @options.min_body_bytes

      true
    end

    def skip(chapter_id, body_bytes)
      log("chapter=#{chapter_id} body=#{body_bytes} skipped: outside size range")
      { chapter_id:, body_bytes: }
    end

    def record!(tallies, result)
      return tallies[:unchanged] += 1 if result.unchanged

      tallies[:compressed] += 1
      tallies[:before_bytes] += result.before_bytes
      tallies[:after_bytes] += result.after_bytes
      log("chapter=#{result.chapter_id} images=#{result.images_compressed} " \
          "bytes=#{result.before_bytes}->#{result.after_bytes}")
    end

    def log(message)
      Rails.logger.info("[CompressBackfill] #{message}")
    end
  end
end
