# frozen_string_literal: true

module Analytics
  # Collects per-action request timings in memory and writes one RequestStat row per action every hour: request
  # count, server errors, and sums plus percentiles of duration, SQL time, query count, view time and response size
  # (RequestStatsBucket). A thread in the web process does the writes; what is left is written before a normal exit
  # and before a code reload in development.
  class RequestStats
    PERIOD = 3600
    MAX_SAMPLES = 20_000
    STOP_WAIT = 10

    class << self
      def default
        @default ||= new
      end

      def shutdown
        @default&.stop
      end
    end

    def initialize(logger: Rails.logger, background: !Rails.env.test?, period: PERIOD, max_samples: MAX_SAMPLES)
      @logger = logger
      @background = background
      @period = period
      @max_samples = max_samples
      @mutex = Mutex.new
      @signal = Thread::Queue.new
      @buckets = {}
      @period_start = current_period_start
    end

    def add_event(event)
      payload = event.payload
      add(endpoint: "#{payload[:controller]}##{payload[:action]}", status: payload[:status].to_i,
          duration_ms: event.duration, **runtime_values(payload))
    rescue StandardError => e
      @logger.error("[RequestStats] skipped a request: #{e.class}: #{e.message}")
    end

    def add(endpoint:, status:, **values)
      @mutex.synchronize do
        (@buckets[endpoint] ||= RequestStatsBucket.new(@max_samples)).add(status, values)
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

    # The last write runs in the caller: a dev code reload holds the lock the thread would need to load models.
    def stop
      thread = @mutex.synchronize { @thread.tap { @thread = nil } }
      return unless thread

      @signal << :stop
      thread.join(STOP_WAIT)
      flush
    end

    private

    def runtime_values(payload)
      { db_ms: payload[:db_runtime].to_f, view_ms: payload[:view_runtime].to_f,
        queries: payload[:queries_count].to_i, bytes: response_bytes(payload[:response]) }
    end

    def response_bytes(response)
      return 0 unless response.respond_to?(:stream) && response.stream.instance_of?(ActionDispatch::Response::Buffer)

      response.body.bytesize
    end

    def run
      Thread.current.name = 'request-stats'
      flush until @signal.pop(timeout: seconds_to_next_period) == :stop
    end

    def write(period_start, buckets)
      created_at = Time.current
      rows = buckets.map { |endpoint, bucket| { period_start:, endpoint:, created_at:, **bucket.to_row } }
      RequestStat.transaction { RequestStat.create!(rows) }
    rescue StandardError => e
      @logger.error("[RequestStats] write failed, dropping #{buckets.size} rows: #{e.class}: #{e.message}")
    end

    def current_period_start
      Time.zone.at((Time.current.to_i / @period) * @period)
    end

    def seconds_to_next_period
      @period - (Time.current.to_i % @period)
    end
  end
end
