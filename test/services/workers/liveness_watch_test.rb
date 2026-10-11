# frozen_string_literal: true

require 'test_helper'

module Workers
  class LivenessWatchTest < ActiveSupport::TestCase
    setup do
      @sent = []
      @watch = LivenessWatch.new(alert: ->(text) { @sent << text })
      @now = Time.current.change(usec: 0)
    end

    test 'stays quiet while every process sends heartbeats and nothing waits' do
      register_processes(at: @now)

      @watch.check(now: @now)
      @watch.check(now: @now + 4.minutes)

      assert_empty @sent
    end

    test 'alerts once a missing heartbeat lasts past the deploy grace' do
      register_processes(at: @now, kinds: %w[Dispatcher Scheduler])

      @watch.check(now: @now)
      @watch.check(now: @now + 2.minutes)

      assert_empty @sent

      @watch.check(now: @now + LivenessWatch::ALERT_AFTER)

      assert_equal 1, @sent.size
      assert_includes @sent.first, 'Worker: немає heartbeat'
    end

    test 'reminds hourly while the worker stays down' do
      @watch.check(now: @now)
      @watch.check(now: @now + LivenessWatch::ALERT_AFTER)
      @watch.check(now: @now + 30.minutes)

      assert_equal 1, @sent.size

      @watch.check(now: @now + LivenessWatch::ALERT_AFTER + LivenessWatch::REMIND_EVERY)

      assert_equal 2, @sent.size
    end

    test 'treats an old heartbeat like a missing process' do
      register_processes(at: @now - 6.minutes)

      @watch.check(now: @now)
      @watch.check(now: @now + LivenessWatch::ALERT_AFTER)

      assert_equal 1, @sent.size
      LivenessWatch::KINDS.each { |kind| assert_includes @sent.first, "#{kind}: немає heartbeat" }
    end

    test 'says so when the worker recovers' do
      @watch.check(now: @now)
      @watch.check(now: @now + LivenessWatch::ALERT_AFTER)
      register_processes(at: @now + LivenessWatch::ALERT_AFTER)
      @watch.check(now: @now + LivenessWatch::ALERT_AFTER + 1.minute)

      assert_equal ['Воркер Solid Queue знову в нормі.'], @sent.drop(1)
    end

    test 'alerts on a job waiting too long, with a longer limit for the heavy queue' do
      register_processes(at: @now + 1.hour)
      ready_job('default', ready_at: @now - 6.minutes)
      ready_job('heavy', ready_at: @now - 10.minutes)

      @watch.check(now: @now)
      @watch.check(now: @now + LivenessWatch::ALERT_AFTER)

      assert_equal 1, @sent.size
      assert_includes @sent.first, 'default: задача чекає на старт 9 хв'
      assert_not_includes @sent.first, 'heavy'
    end

    test 'a failed check is logged, not raised' do
      log = StringIO.new
      watch = LivenessWatch.new(alert: ->(_) {}, logger: Logger.new(log))

      SolidQueue::Process.stub(:where, ->(*) { raise ActiveRecord::ConnectionNotEstablished }) do
        watch.send(:safe_check)
      end

      assert_includes log.string, '[LivenessWatch] check failed: ActiveRecord::ConnectionNotEstablished'
    end

    private

    def register_processes(at:, kinds: LivenessWatch::KINDS)
      kinds.each do |kind|
        SolidQueue::Process.create!(kind:, name: "#{kind.downcase}-#{SecureRandom.hex(4)}", pid: 1, hostname: 'test',
                                    last_heartbeat_at: at)
      end
    end

    def ready_job(queue_name, ready_at:)
      travel_to(ready_at) { SolidQueue::Job.create!(queue_name:, class_name: 'TestJob', arguments: {}) }
    end
  end
end
