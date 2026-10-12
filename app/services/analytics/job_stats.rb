# frozen_string_literal: true

module Analytics
  # Collects Active Job runs in the Solid Queue worker and writes one JobStat row per job class every hour: runs,
  # failures, total and longest run time, and total and longest wait from enqueue (or the scheduled time) to start.
  # Rows outlive deploys, which wipe the worker's logs. Jobs over SLOW_AFTER_MS also get a log line with the process
  # RSS before and after; in async mode that RSS covers every job running at the same time.
  class JobStats
    PERIOD = 3600
    SLOW_AFTER_MS = 10_000
    STOP_WAIT = 10

    class << self
      def default
        @default ||= new
      end

      def shutdown
        @default&.stop
      end

      def subscribe
        ActiveSupport::Notifications.subscribe('perform_start.active_job') do |event|
          default.job_started(event.payload[:job])
        end
        ActiveSupport::Notifications.subscribe('perform.active_job') { |event| default.job_finished(event) }
      end
    end

    def initialize(logger: Rails.logger, background: !Rails.env.test?, period: PERIOD,
                   rss: -> { Workers::MemoryGuard.rss_mb })
      @logger = logger
      @background = background
      @period = period
      @rss = rss
      @mutex = Mutex.new
      @signal = Thread::Queue.new
      @starts = {}
      @buckets = {}
      @period_start = current_period_start
    end

    def job_started(job)
      start = [@rss.call, wait_ms(job)]
      @mutex.synchronize { @starts[job.job_id] = start }
    rescue StandardError => e
      @logger.error("[JobStats] skipped a job start: #{e.class}: #{e.message}")
    end

    def job_finished(event)
      job = event.payload[:job]
      duration_ms = event.duration
      rss_before, wait_ms = @mutex.synchronize { @starts.delete(job.job_id) } || [nil, 0.0]
      log_slow(job, duration_ms, wait_ms, rss_before) if duration_ms >= SLOW_AFTER_MS
      add(job_class: job.class.name, duration_ms:, wait_ms:, error: event.payload[:exception_object])
    rescue StandardError => e
      @logger.error("[JobStats] skipped a job: #{e.class}: #{e.message}")
    end

    def add(job_class:, duration_ms:, wait_ms:, error: nil)
      @mutex.synchronize do
        (@buckets[job_class] ||= JobStatsBucket.new).add(duration_ms, wait_ms, error)
        @thread = Thread.new { run } if @background && !@thread&.alive?
      end
    end

    def flush
      period_start, buckets = @mutex.synchronize do
        [@period_start, @buckets].tap do
          @buckets = {}
          @period_start = current_period_start
        end
      end
      write(period_start, buckets) if buckets.any?
    end

    def stop
      thread = @mutex.synchronize { @thread.tap { @thread = nil } }
      if thread
        @signal << :stop
        thread.join(STOP_WAIT)
      end
      flush
    end

    private

    def wait_ms(job)
      queued_at = job.scheduled_at || job.enqueued_at
      queued_at ? [(Time.current - queued_at) * 1000, 0.0].max : 0.0
    end

    def log_slow(job, duration_ms, wait_ms, rss_before)
      rss_after = @rss.call
      rss = rss_before && rss_after ? "#{rss_before}->#{rss_after}MB" : '-'
      @logger.info("[SlowJob] #{job.class.name} #{format('%.1f', duration_ms.fdiv(1000))}s " \
                   "wait=#{format('%.1f', wait_ms.fdiv(1000))}s rss=#{rss} queue=#{job.queue_name} id=#{job.job_id}")
    end

    def run
      Thread.current.name = 'job-stats'
      flush until @signal.pop(timeout: seconds_to_next_period) == :stop
    end

    def write(period_start, buckets)
      created_at = Time.current
      rows = buckets.map { |job_class, bucket| { period_start:, job_class:, created_at:, **bucket.to_row } }
      JobStat.transaction { JobStat.create!(rows) }
    rescue StandardError => e
      @logger.error("[JobStats] write failed, dropping #{buckets.size} rows: #{e.class}: #{e.message}")
    end

    def current_period_start
      Time.zone.at((Time.current.to_i / @period) * @period)
    end

    def seconds_to_next_period
      @period - (Time.current.to_i % @period)
    end
  end
end
