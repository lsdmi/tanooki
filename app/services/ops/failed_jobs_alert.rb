# frozen_string_literal: true

module Ops
  # Tells the ops channel about jobs that failed since the last triage run (every 2 hours), grouped by class with the
  # first error of each. Failures are rare (2 in the two weeks to 2026-10-11), so a single one is worth a message.
  # Runs before triage retries anything, because a retry deletes the failed execution.
  class FailedJobsAlert
    WINDOW = 2.hours
    TOP_CLASSES = 5
    ERROR_LENGTH = 200

    def self.call(...)
      new(...).call
    end

    def initialize(since: WINDOW.ago, alert: Alert)
      @since = since
      @alert = alert
    end

    def call
      failures = SolidQueue::FailedExecution.includes(:job).where(created_at: @since..).order(:created_at).to_a
      return if failures.empty?

      @alert.call(message(failures))
    end

    private

    def message(failures)
      groups = failures.group_by { |failure| failure.job.class_name }.sort_by { |_, list| -list.size }
      lines = groups.first(TOP_CLASSES).map do |class_name, list|
        "• <b>#{h(class_name)}</b> × #{list.size}: #{h(error_line(list.first))}"
      end
      ["Збої задач за останні 2 год: #{failures.size}", *lines].join("\n")
    end

    def error_line(failure)
      "#{failure.exception_class}: #{failure.message}".squish.truncate(ERROR_LENGTH)
    end

    def h(text)
      ERB::Util.html_escape(text)
    end
  end
end
