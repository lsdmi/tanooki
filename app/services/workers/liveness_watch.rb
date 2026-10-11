# frozen_string_literal: true

module Workers
  # App Platform has no health check for workers, so a hung Solid Queue worker would look healthy. A thread in the web
  # process (another container, so it keeps running when the worker hangs) checks every minute that the worker's
  # processes still send heartbeats and that no job has waited too long to start. It tells the ops channel when that
  # goes wrong, reminds every hour while it stays wrong, and says when it is fine again. Puma runs single-process, so
  # there is one watcher per web container.
  class LivenessWatch
    CHECK_EVERY = 60
    STOP_WAIT = 5
    KINDS = %w[Worker Dispatcher Scheduler].freeze
    HEARTBEAT_STALE_AFTER = 5.minutes
    READY_WAIT_LIMIT = 5.minutes
    # One thread builds EPUBs one after another; a short burst of long builds can queue this long without a fault.
    HEAVY_READY_WAIT_LIMIT = 15.minutes
    # A deploy swaps worker containers, so processes can be missing for a moment.
    ALERT_AFTER = 3.minutes
    REMIND_EVERY = 1.hour

    class << self
      def default
        @default ||= new
      end

      def shutdown
        @default&.stop
      end
    end

    def initialize(check_every: CHECK_EVERY, alert: Ops::Alert, logger: Rails.logger)
      @check_every = check_every
      @alert = alert
      @logger = logger
      @signal = Thread::Queue.new
      @failing_since = nil
      @alerted_at = nil
    end

    def start
      @thread ||= Thread.new { run }
      self
    end

    def stop
      return unless @thread

      @signal << :stop
      @thread.join(STOP_WAIT)
      @thread = nil
    end

    def check(now: Time.current)
      problems = SolidQueue::Record.with_connection { stale_kinds(now) + slow_queues(now) }
      problems.empty? ? healthy : failing(problems, now)
    end

    private

    def run
      Thread.current.name = 'liveness-watch'
      loop do
        break if @signal.pop(timeout: @check_every) == :stop

        safe_check
      end
    end

    def safe_check
      check
    rescue StandardError => e
      @logger.error("[LivenessWatch] check failed: #{e.class}: #{e.message}")
    end

    def stale_kinds(now)
      fresh = SolidQueue::Process.where(last_heartbeat_at: (now - HEARTBEAT_STALE_AFTER)..).distinct.pluck(:kind)
      (KINDS - fresh).map { |kind| "#{kind}: немає heartbeat понад #{HEARTBEAT_STALE_AFTER.in_minutes.to_i} хв" }
    end

    def slow_queues(now)
      SolidQueue::ReadyExecution.group(:queue_name).minimum(:created_at).filter_map do |queue, oldest|
        waited = now - oldest
        next if waited < ready_wait_limit(queue)

        "#{queue}: задача чекає на старт #{(waited / 60).floor} хв"
      end
    end

    def ready_wait_limit(queue)
      queue.end_with?('heavy') ? HEAVY_READY_WAIT_LIMIT : READY_WAIT_LIMIT
    end

    def failing(problems, now)
      @failing_since ||= now
      return if now - @failing_since < ALERT_AFTER
      return if @alerted_at && now - @alerted_at < REMIND_EVERY

      @alerted_at = now
      lines = problems.map { |problem| "• #{ERB::Util.html_escape(problem)}" }
      @alert.call(["Воркер Solid Queue не в нормі з #{@failing_since.utc.strftime('%H:%M')} UTC:", *lines].join("\n"))
    end

    def healthy
      @alert.call('Воркер Solid Queue знову в нормі.') if @alerted_at
      @failing_since = nil
      @alerted_at = nil
    end
  end
end
