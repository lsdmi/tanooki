# frozen_string_literal: true

module Books
  # Logs worker RSS around one EPUB build and keeps it as an EpubExportStat, to size
  # EpubExportLimits::MAX_SOURCE_BYTES against real exports (deploys cut the logs). The peak is sampled (App Platform
  # does not allow resetting VmHWM) and covers the whole process, other queues' jobs too. Without /proc (macOS)
  # nothing is recorded.
  class EpubExportMemory
    SAMPLE_EVERY = 0.25

    def self.measure(export_request, &)
      new(export_request).measure(&)
    end

    def initialize(export_request, memory: Workers::MemoryGuard, logger: Rails.logger, sample_every: SAMPLE_EVERY)
      @export_request = export_request
      @memory = memory
      @logger = logger
      @sample_every = sample_every
    end

    def measure
      before = @memory.rss_mb
      return yield unless before

      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      sampler, stop = start_sampler(before)
      epub_export = yield
    ensure
      if before
        stop&.push(true)
        record(before, sampler, started, epub_export)
      end
    end

    private

    def start_sampler(before)
      stop = Thread::Queue.new
      sampler = Thread.new do
        peak = before
        peak = [peak, @memory.rss_mb.to_i].max until stop.pop(timeout: @sample_every)
        peak
      end
      [sampler, stop]
    end

    def record(before, sampler, started, epub_export)
      stat = stat_attributes(before, sampler, started, epub_export)
      @logger.info(log_line(stat))
      EpubExportStat.create!(stat)
    rescue StandardError => e
      @logger.warn("[EPUB memory] request=#{@export_request.id} record failed: #{e.class}: #{e.message}")
    end

    def stat_attributes(before, sampler, started, epub_export)
      after = @memory.rss_mb.to_i
      ids = @export_request.rich_text_ids
      { epub_export_request_id: @export_request.id, user_id: @export_request.user_id, chapters: ids.size,
        source_bytes: EpubExportLimits.source_bytes(ids), epub_bytes: epub_export && File.size?(epub_export.file_path),
        rss_before_mb: before, rss_peak_mb: [sampler.value, after].max, rss_after_mb: after,
        seconds: (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started).round(1) }
    end

    def log_line(stat)
      "[EPUB memory] request=#{stat[:epub_export_request_id]} chapters=#{stat[:chapters]} " \
        "source=#{megabytes(stat[:source_bytes])} epub=#{megabytes(stat[:epub_bytes])} " \
        "rss_before=#{stat[:rss_before_mb]}MB peak=#{stat[:rss_peak_mb]}MB rss_after=#{stat[:rss_after_mb]}MB " \
        "seconds=#{stat[:seconds]}"
    end

    def megabytes(bytes)
      bytes ? "#{(bytes.to_f / 1.megabyte).round(1)}MB" : '-'
    end
  end
end
