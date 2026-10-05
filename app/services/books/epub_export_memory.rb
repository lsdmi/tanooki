# frozen_string_literal: true

module Books
  # Logs worker RSS around one EPUB build, to size EpubExportLimits::MAX_SOURCE_BYTES against real exports.
  # The peak is sampled (App Platform does not allow resetting VmHWM) and covers the whole process, other queues'
  # jobs too. Without /proc (macOS) nothing is logged.
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
        log(before, sampler, started, epub_export)
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

    def log(before, sampler, started, epub_export)
      seconds = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started).round(1)
      after = @memory.rss_mb.to_i
      peak = [sampler.value, after].max
      @logger.info("[EPUB memory] request=#{@export_request.id} #{sizes(epub_export)} rss_before=#{before}MB " \
                   "peak=#{peak}MB rss_after=#{after}MB seconds=#{seconds}")
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
