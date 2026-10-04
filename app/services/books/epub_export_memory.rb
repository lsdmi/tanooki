# frozen_string_literal: true

module Books
  # Logs worker RSS around one EPUB build, to size EpubExportLimits::MAX_SOURCE_BYTES against real exports.
  # The peak covers the whole process (other queues' jobs too); without /proc (macOS) nothing is logged.
  class EpubExportMemory
    def self.measure(export_request, &)
      new(export_request).measure(&)
    end

    def initialize(export_request, memory: Workers::MemoryGuard, logger: Rails.logger)
      @export_request = export_request
      @memory = memory
      @logger = logger
    end

    def measure
      before = @memory.rss_mb
      return yield unless before

      peak_tracked = @memory.reset_peak_rss
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      epub_export = yield
    ensure
      log(before, peak_tracked, started, epub_export) if before
    end

    private

    def log(before, peak_tracked, started, epub_export)
      seconds = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started).round(1)
      peak = peak_tracked ? "#{@memory.peak_rss_mb}MB" : '-'
      @logger.info("[EPUB memory] request=#{@export_request.id} #{sizes(epub_export)} rss_before=#{before}MB " \
                   "peak=#{peak} rss_after=#{@memory.rss_mb}MB seconds=#{seconds}")
    rescue StandardError => e
      @logger.warn("[EPUB memory] request=#{@export_request.id} log failed: #{e.class}: #{e.message}")
    end

    def sizes(epub_export)
      ids = @export_request.rich_text_ids
      epub_bytes = epub_export && File.size?(epub_export.file_path)
      "chapters=#{ids.size} source=#{megabytes(EpubExportLimits.source_bytes(ids))} epub=#{megabytes(epub_bytes)}"
    end

    def megabytes(bytes)
      bytes ? "#{(bytes.to_f / 1.megabyte).round(1)}MB" : '-'
    end
  end
end
