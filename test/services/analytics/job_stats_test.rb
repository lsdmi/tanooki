# frozen_string_literal: true

require 'test_helper'

module Analytics
  class JobStatsTest < ActiveSupport::TestCase
    Event = Struct.new(:payload, :duration)

    setup do
      @log = StringIO.new
      @rss = 400
      @stats = JobStats.new(logger: Logger.new(@log), background: false, rss: -> { @rss })
    end

    test 'writes one row per job class with runs, failures, times and the first error' do
      run_job(Fictions::WarmIndexCacheJob.new, duration: 120, waited: 2.seconds)
      run_job(Fictions::WarmIndexCacheJob.new, duration: 80, waited: 4.seconds, error: RuntimeError.new('cache down'))
      run_job(Books::PurgeExpiredEpubExportsJob.new, duration: 30, waited: 1.second)

      assert_difference -> { JobStat.count }, 2 do
        @stats.flush
      end

      row = JobStat.find_by!(job_class: 'Fictions::WarmIndexCacheJob')

      assert_equal [2, 1, 200.0, 120.0, 'RuntimeError: cache down'],
                   [row.jobs, row.failures, row.duration_ms_sum, row.duration_ms_max, row.error_sample]
      assert_in_delta 4000, row.wait_ms_max, 50
    end

    test 'measures the wait from the scheduled time when there is one' do
      job = Fictions::WarmIndexCacheJob.new
      job.enqueued_at = 1.hour.ago
      job.scheduled_at = 5.seconds.ago
      @stats.job_started(job)
      @stats.job_finished(Event.new({ job: }, 10))
      @stats.flush

      assert_in_delta 5000, JobStat.last.wait_ms_max, 50
    end

    test 'logs jobs over ten seconds with RSS before and after' do
      job = Fictions::WarmIndexCacheJob.new
      job.enqueued_at = Time.current
      @stats.job_started(job)
      @rss = 468
      @stats.job_finished(Event.new({ job: }, 72_300))

      assert_includes @log.string, '[SlowJob] Fictions::WarmIndexCacheJob 72.3s wait=0.0s rss=400->468MB ' \
                                   "queue=#{job.queue_name} id=#{job.job_id}"
    end

    test 'quick jobs get no log line' do
      run_job(Fictions::WarmIndexCacheJob.new, duration: 9_999, waited: 0.seconds)

      assert_empty @log.string
    end

    test 'a failed write is logged, not raised' do
      run_job(Fictions::WarmIndexCacheJob.new, duration: 10, waited: 0.seconds)

      JobStat.stub(:create!, ->(*) { raise ActiveRecord::ConnectionNotEstablished }) { @stats.flush }

      assert_includes @log.string, '[JobStats] write failed, dropping 1 rows'
    end

    private

    def run_job(job, duration:, waited:, error: nil)
      job.enqueued_at = waited.ago
      @stats.job_started(job)
      @stats.job_finished(Event.new({ job:, exception_object: error }, duration))
    end
  end
end
