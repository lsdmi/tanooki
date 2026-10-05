# frozen_string_literal: true

require 'test_helper'

module Analytics
  class RequestStatsTest < ActiveSupport::TestCase
    setup do
      @log = StringIO.new
      @stats = RequestStats.new(background: false, logger: Logger.new(@log))
    end

    test 'writes one row per action with counts, sums and percentiles' do
      (1..20).each do |ms|
        @stats.add(endpoint: 'ChaptersController#show', status: ms == 20 ? 500 : 200, duration_ms: ms.to_f,
                   db_ms: 1.0, view_ms: 2.0, queries: ms, bytes: 1000)
      end
      @stats.add(endpoint: 'HomeController#index', status: 200, duration_ms: 7.0, db_ms: 0.5, view_ms: 3.0,
                 queries: 4, bytes: 500)

      assert_difference('RequestStat.count', 2) { @stats.flush }

      show = RequestStat.find_by!(endpoint: 'ChaptersController#show')

      assert_equal [20, 1, 210.0, 10.0, 19.0, 20.0], show.values_at(:requests, :server_errors, :duration_ms_sum,
                                                                    :duration_ms_p50, :duration_ms_p95,
                                                                    :duration_ms_max)
      assert_equal [20.0, 1.0, 40.0, 210, 19, 20_000, 1000], show.values_at(:db_ms_sum, :db_ms_p95, :view_ms_sum,
                                                                            :queries_sum, :queries_p95, :bytes_sum,
                                                                            :bytes_p95)
    end

    test 'rows belong to the hour the requests came in' do
      @stats.add(endpoint: 'HomeController#index', status: 200, duration_ms: 7.0, db_ms: 0.5, view_ms: 3.0,
                 queries: 4, bytes: 500)
      @stats.flush

      assert_equal Time.zone.at((Time.current.to_i / 3600) * 3600), RequestStat.last.period_start
    end

    test 'nothing to write, no query' do
      assert_no_queries { @stats.flush }
    end

    test 'keeps exact counts and sums past the sample cap' do
      stats = RequestStats.new(background: false, max_samples: 5)
      100.times do
        stats.add(endpoint: 'ChaptersController#show', status: 200, duration_ms: 10.0, db_ms: 1.0, view_ms: 1.0,
                  queries: 3, bytes: 100)
      end

      assert_equal 5, stats.instance_variable_get(:@buckets)['ChaptersController#show'].samples.size

      stats.flush

      assert_equal [100, 1000.0, 300, 10.0],
                   RequestStat.last.values_at(:requests, :duration_ms_sum, :queries_sum, :duration_ms_p95)
    end

    test 'a failed write is logged and the next hour starts empty' do
      @stats.add(endpoint: 'HomeController#index', status: 200, duration_ms: 7.0, db_ms: 0.5, view_ms: 3.0,
                 queries: 4, bytes: 500)

      RequestStat.stub(:create!, ->(*) { raise ActiveRecord::ConnectionNotEstablished }) { @stats.flush }

      assert_includes @log.string, '[RequestStats] write failed, dropping 1 rows'
      assert_no_difference('RequestStat.count') { @stats.flush }
    end

    test 'stop writes what is left and ends the thread' do
      stats = RequestStats.new(background: true)
      stats.add(endpoint: 'HomeController#index', status: 200, duration_ms: 7.0, db_ms: 0.5, view_ms: 3.0,
                queries: 4, bytes: 500)
      thread = stats.instance_variable_get(:@thread)

      assert_difference('RequestStat.count', 1) { stats.stop }
      assert_not thread.alive?
    end
  end
end
