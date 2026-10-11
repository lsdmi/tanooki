# frozen_string_literal: true

require 'test_helper'

module Ops
  class FailedJobsAlertTest < ActiveSupport::TestCase
    setup do
      @sent = []
      @alert = ->(text) { @sent << text }
    end

    test 'sends nothing when no job failed in the window' do
      travel_to(3.hours.ago) { fail_job('Books::GenerateEpubJob', RuntimeError.new('old')) }

      FailedJobsAlert.call(alert: @alert)

      assert_empty @sent
    end

    test 'groups recent failures by class, busiest first, with the first error escaped' do
      fail_job('ActiveStorage::PurgeJob', RuntimeError.new('gone'))
      2.times { |i| fail_job('Books::GenerateEpubJob', ArgumentError.new("bad <chapter> #{i}")) }

      FailedJobsAlert.call(alert: @alert)

      assert_equal [<<~TEXT.chomp], @sent
        Збої задач за останні 2 год: 3
        • <b>Books::GenerateEpubJob</b> × 2: ArgumentError: bad &lt;chapter&gt; 0
        • <b>ActiveStorage::PurgeJob</b> × 1: RuntimeError: gone
      TEXT
    end

    test 'triage reports failures before retrying them' do
      fail_job('Books::GenerateEpubJob', RuntimeError.new('boom'))
      sent = []

      Alert.stub(:call, ->(text) { sent << text }) { SolidQueue::TriageFailedJobsJob.perform_now }

      assert_includes sent.first, 'Books::GenerateEpubJob'
      assert_equal 0, SolidQueue::FailedExecution.count
    end

    test 'triage still cleans up when the alert fails' do
      fail_job('Books::GenerateEpubJob', RuntimeError.new('boom'))

      Alert.stub(:call, ->(*) { raise SocketError, 'Telegram unreachable' }) do
        SolidQueue::TriageFailedJobsJob.perform_now
      end

      assert_equal 0, SolidQueue::FailedExecution.count
    end

    private

    def fail_job(class_name, error)
      SolidQueue::Job.create!(queue_name: 'default', class_name:, arguments: {}).failed_with(error)
    end
  end
end
