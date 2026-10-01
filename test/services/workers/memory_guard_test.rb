# frozen_string_literal: true

require 'test_helper'

module Workers
  class MemoryGuardTest < ActiveSupport::TestCase
    setup do
      @log = StringIO.new
      @stops = 0
      @guard = MemoryGuard.new(limit_mb: 750, logger: Logger.new(@log), stop: -> { @stops += 1 })
    end

    test 'logs on the first check and then every five minutes' do
      @guard.stub(:rss_mb, 400) do
        @guard.check(now: 0)
        @guard.check(now: 30)
        @guard.check(now: MemoryGuard::LOG_EVERY)
      end

      assert_equal 2, @log.string.scan('[MemoryGuard] rss=400MB').size
      assert_equal 0, @stops
    end

    test 'stops the worker once when RSS reaches the limit' do
      @guard.stub(:rss_mb, 760) do
        @guard.check(now: 0)
        @guard.check(now: 30)
      end

      assert_equal 1, @stops
      assert_includes @log.string, 'rss=760MB over 750MB'
    end

    test 'does nothing when RSS cannot be read' do
      @guard.stub(:rss_mb, nil) do
        assert_nil @guard.start
        @guard.check(now: 0)
      end

      assert_includes @log.string, "[MemoryGuard] off: #{MemoryGuard::PROC_STATUS} not readable"
      assert_equal 0, @stops
    end

    test 'reads VmRSS from proc status in megabytes' do
      File.stub(:foreach, ["Name:\truby\n", "VmRSS:\t  524288 kB\n"].each) do
        assert_equal 512, @guard.rss_mb
      end
    end

    test 'the limit can be changed with WORKER_MEMORY_LIMIT_MB' do
      ENV['WORKER_MEMORY_LIMIT_MB'] = '600'
      guard = MemoryGuard.new(logger: Logger.new(@log), stop: -> { @stops += 1 })
      guard.stub(:rss_mb, 650) { guard.check(now: 0) }

      assert_equal 1, @stops
    ensure
      ENV.delete('WORKER_MEMORY_LIMIT_MB')
    end
  end
end
