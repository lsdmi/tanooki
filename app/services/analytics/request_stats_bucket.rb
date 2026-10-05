# frozen_string_literal: true

module Analytics
  # One action's requests within one RequestStats period. Counts, sums and the slowest duration are exact; percentiles
  # come from at most max_samples samples (a random subset once there are more).
  class RequestStatsBucket
    METRICS = %i[duration_ms db_ms view_ms queries bytes].freeze

    attr_reader :samples

    def initialize(max_samples)
      @max_samples = max_samples
      @requests = 0
      @server_errors = 0
      @sums = Array.new(METRICS.size, 0)
      @max_duration_ms = 0
      @samples = []
    end

    def add(status, values)
      sample = METRICS.map { |metric| values.fetch(metric) }
      @requests += 1
      @server_errors += 1 if status >= 500
      @sums = @sums.zip(sample).map(&:sum)
      @max_duration_ms = [@max_duration_ms, sample.first].max
      keep(sample)
    end

    def to_row
      sorted = @samples.transpose.map(&:sort)
      row = { requests: @requests, server_errors: @server_errors, duration_ms_max: @max_duration_ms,
              duration_ms_p50: percentile(sorted.first, 0.5) }
      METRICS.each_with_index do |metric, index|
        row[:"#{metric}_sum"] = @sums[index]
        row[:"#{metric}_p95"] = percentile(sorted[index], 0.95)
      end
      row
    end

    private

    def keep(sample)
      if @samples.size < @max_samples
        @samples << sample
      elsif (slot = rand(@requests)) < @max_samples
        @samples[slot] = sample
      end
    end

    def percentile(sorted, fraction)
      sorted[((sorted.size * fraction).ceil - 1).clamp(0, sorted.size - 1)]
    end
  end
end
