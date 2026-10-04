# frozen_string_literal: true

module Workers
  # Restarts the Solid Queue worker before the 1 GB container runs out of memory. A thread reads the process RSS
  # every 30 s and logs it every 5 minutes; above the limit it sends TERM to its own process, so Solid Queue stops
  # taking jobs, lets running ones finish (SolidQueue.shutdown_timeout) and exits, and App Platform starts a fresh
  # container. Decides on RSS, not the cgroup total, which also counts file cache the kernel reclaims on its own.
  # Async mode only: in fork mode this process is just the supervisor.
  class MemoryGuard
    LIMIT_MB = 750
    CHECK_EVERY = 30
    LOG_EVERY = 300
    PROC_STATUS = '/proc/self/status'
    PROC_CLEAR_REFS = '/proc/self/clear_refs'
    CGROUP_FILES = %w[/sys/fs/cgroup/memory.current /sys/fs/cgroup/memory/memory.usage_in_bytes].freeze

    def self.start(**)
      new(**).start
    end

    def self.rss_mb
      status_mb('VmRSS:')
    end

    # Highest RSS since the process started or since the last reset_peak_rss.
    def self.peak_rss_mb
      status_mb('VmHWM:')
    end

    def self.reset_peak_rss
      File.write(PROC_CLEAR_REFS, '5')
      true
    rescue SystemCallError
      false
    end

    def self.status_mb(field)
      line = File.foreach(PROC_STATUS).find { |status_line| status_line.start_with?(field) }
      line && (line[/\d+/].to_i / 1024)
    rescue SystemCallError
      nil
    end

    def initialize(limit_mb: ENV.fetch('WORKER_MEMORY_LIMIT_MB', LIMIT_MB).to_i, logger: Rails.logger,
                   stop: -> { Process.kill('TERM', Process.pid) })
      @limit_mb = limit_mb
      @logger = logger
      @stop = stop
      @last_logged_at = nil
      @stopping = false
    end

    def start
      unless rss_mb
        @logger.info("[MemoryGuard] off: #{PROC_STATUS} not readable")
        return
      end

      @thread = Thread.new { run }
      self
    end

    def check(now: Process.clock_gettime(Process::CLOCK_MONOTONIC))
      rss = rss_mb
      return unless rss

      log(rss, now) if @last_logged_at.nil? || now - @last_logged_at >= LOG_EVERY
      stop_worker(rss) if rss >= @limit_mb && !@stopping
    end

    delegate :rss_mb, to: :class

    def cgroup_mb
      path = CGROUP_FILES.find { |file| File.readable?(file) }
      path && (File.read(path).to_i / 1024 / 1024)
    end

    # Compiled code plus YJIT's own metadata, to weigh it against DISABLE_YJIT (config/application.rb).
    def yjit_mb
      return unless defined?(RubyVM::YJIT) && RubyVM::YJIT.enabled?

      (RubyVM::YJIT.runtime_stats(:code_region_size).to_i + RubyVM::YJIT.runtime_stats(:yjit_alloc_size).to_i) /
        1024 / 1024
    end

    private

    def run
      loop do
        check
      rescue StandardError => e
        @logger.error("[MemoryGuard] check failed: #{e.class}: #{e.message}")
      ensure
        sleep CHECK_EVERY
      end
    end

    def log(rss, now)
      @last_logged_at = now
      yjit = yjit_mb
      @logger.info("[MemoryGuard] rss=#{rss}MB cgroup=#{cgroup_mb || '-'}MB yjit=#{yjit ? "#{yjit}MB" : 'off'} " \
                   "limit=#{@limit_mb}MB")
    end

    def stop_worker(rss)
      @stopping = true
      @logger.warn("[MemoryGuard] rss=#{rss}MB over #{@limit_mb}MB: stopping the worker gracefully for a restart")
      @stop.call
    end
  end
end
