# frozen_string_literal: true

module Analytics
  # One job class's runs within one JobStats period. A run that raised counts as a failure, retries included.
  class JobStatsBucket
    def initialize
      @jobs = 0
      @failures = 0
      @duration_ms_sum = 0.0
      @duration_ms_max = 0.0
      @wait_ms_sum = 0.0
      @wait_ms_max = 0.0
      @error_sample = nil
    end

    def add(duration_ms, wait_ms, error)
      @jobs += 1
      @duration_ms_sum += duration_ms
      @duration_ms_max = [@duration_ms_max, duration_ms].max
      @wait_ms_sum += wait_ms
      @wait_ms_max = [@wait_ms_max, wait_ms].max
      return unless error

      @failures += 1
      @error_sample = "#{error.class}: #{error.message}".squish.truncate(500) if @failures == 1
    end

    def to_row
      { jobs: @jobs, failures: @failures, duration_ms_sum: @duration_ms_sum, duration_ms_max: @duration_ms_max,
        wait_ms_sum: @wait_ms_sum, wait_ms_max: @wait_ms_max, error_sample: @error_sample }
    end
  end
end
